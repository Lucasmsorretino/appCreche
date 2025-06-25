from sqlmodel import SQLModel, Field, Relationship
from typing import Optional, TYPE_CHECKING
from datetime import datetime

if TYPE_CHECKING:
    from .user import Child

class SaudeRecord(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    date: datetime = Field(default_factory=datetime.now)
    child_id: int = Field(foreign_key="child.id")
    medicacao: Optional[str] = None
    sintomas: Optional[str] = None
    observacoes: Optional[str] = None
    temperatura: Optional[float] = None
    
    # Relationships
    child: "Child" = Relationship(back_populates="saude_records")