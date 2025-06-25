from fastapi import FastAPI
from starlette.middleware.cors import CORSMiddleware
from routes import token_routes, aviso_routes, rotina_routes, saude_routes, calendario_routes, user_routes
from database.db import create_db_and_tables, get_engine
from create_test_user import create_test_user
from sqlmodel import select, SQLModel, Session, text
import datetime
import platform
import os

app = FastAPI(title="CMEI App API")

# Configurar CORS para permitir requisições do frontend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # ou especificar URL do frontend
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.on_event("startup")
def on_startup():
    create_db_and_tables()
    # Criar usuário de teste automaticamente
    try:
        create_test_user()
    except Exception as e:
        print(f"Falha ao criar usuário de teste: {e}")

# Adicionar rota de health check para monitoramento da API
@app.get("/health")
def health_check():
    """
    Verifica a saúde da API e conectividade com o banco de dados.
    Retorna 200 OK se tudo estiver funcionando corretamente.
    """
    result = {
        "status": "healthy", 
        "api_version": "1.0.0", 
        "timestamp": str(datetime.datetime.now()),
        "environment": {
            "python_version": platform.python_version(),
            "system": platform.system(),
            "machine": platform.machine()
        }
    }
    
    try:
        # Verificar conexão com banco de dados
        engine = get_engine()
        with Session(engine) as session:
            # Executar uma consulta simples para verificar o banco
            start_time = datetime.datetime.now()
            session.exec(select(1)).one()
            end_time = datetime.datetime.now()
            
            # Calcular latência do banco
            db_latency = (end_time - start_time).total_seconds() * 1000  # em milissegundos
            
            result["database"] = {
                "status": "connected",
                "latency_ms": round(db_latency, 2),
                "url": str(engine.url).replace('://', '://**:**@')  # Ocultar senha se houver
            }
            
            # Obter estatísticas do banco
            stats = {}
            
            # Listar todas as tabelas
            tables_query = session.exec(text("SELECT name FROM sqlite_master WHERE type='table'")).all()
            tables = [t[0] for t in tables_query]
            stats["tables"] = tables
            
            # Contar registros em tabelas principais
            table_stats = {}
            for table in tables:
                if table != "sqlite_sequence" and not table.startswith("sqlite_"):
                    try:
                        count_query = session.exec(text(f"SELECT COUNT(*) FROM {table}")).one()
                        table_stats[table] = count_query[0]
                    except Exception as e:
                        table_stats[table] = f"error: {str(e)}"
            
            stats["record_counts"] = table_stats
            
            # Verificar e exibir estrutura da tabela avisos
            if "avisos" in tables:
                try:
                    schema = session.exec(text("PRAGMA table_info(avisos)")).all()
                    columns = [{"name": col[1], "type": col[2]} for col in schema]
                    stats["avisos_schema"] = columns
                    
                    # Verificar se há avisos
                    count = table_stats.get("avisos", 0)
                    if count > 0:
                        # Exibir apenas o último aviso como exemplo
                        latest_aviso = session.exec(text("SELECT * FROM avisos ORDER BY id DESC LIMIT 1")).all()
                        if latest_aviso:
                            stats["latest_aviso"] = {
                                "id": latest_aviso[0][0],
                                "titulo": latest_aviso[0][1],
                                "data": latest_aviso[0][3]
                            }
                except Exception as e:
                    stats["avisos_schema"] = f"error: {str(e)}"
            
            result["db_stats"] = stats
            
        return result
    except Exception as e:
        error_info = {"type": type(e).__name__, "message": str(e)}
        return {"status": "unhealthy", "error": error_info}, 500

# Inclusão de rotas
app.include_router(user_routes.router)
app.include_router(aviso_routes.router)
app.include_router(rotina_routes.router)
app.include_router(saude_routes.router)
app.include_router(calendario_routes.router)
app.include_router(token_routes.router)
