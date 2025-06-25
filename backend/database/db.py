from sqlmodel import SQLModel, create_engine
import os

# Define database URL - using sqlite for development
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./cmei_app.db")

# Create engine
engine = create_engine(DATABASE_URL, echo=True)

def create_db_and_tables():
    """Create all tables defined in the models"""
    SQLModel.metadata.create_all(engine)

def get_engine():
    """Return the engine instance"""
    return engine