import pytest
from httpx import AsyncClient
from main import app

@pytest.mark.asyncio
async def test_login_and_protected_route():
    async with AsyncClient(app=app, base_url="http://test") as ac:
        # Simula login com usuário de exemplo
        response = await ac.post("/token", data={"username": "lucas", "password": "senha123"})
        assert response.status_code == 200
        token = response.json().get("access_token")
        assert token is not None

        # Testa uma rota protegida usando o token
        headers = {"Authorization": f"Bearer {token}"}
        protected_response = await ac.get("/avisos", headers=headers)

        # Valida se conseguiu acessar com sucesso
        assert protected_response.status_code in (200, 404)  # 404 se não houver avisos
