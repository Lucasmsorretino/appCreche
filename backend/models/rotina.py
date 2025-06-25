from sqlmodel import SQLModel, Field, Relationship
from typing import Optional, TYPE_CHECKING
from datetime import datetime

if TYPE_CHECKING:
    from .user import Child

class Rotina(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    date: datetime = Field(default_factory=datetime.now)
    child_id: int = Field(foreign_key="child.id")
    alimentacao: str  # Could be more structured in future versions
    sono: str
    atividades: str
    observacoes: Optional[str] = None
    
    # Relationships
    child: "Child" = Relationship(back_populates="rotinas")