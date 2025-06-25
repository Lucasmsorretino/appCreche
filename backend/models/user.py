from sqlmodel import SQLModel, Field, Relationship
from typing import Optional, List, TYPE_CHECKING
from datetime import datetime
from enum import Enum

if TYPE_CHECKING:
    from .aviso import Aviso
    from .rotina import Rotina
    from .saude import SaudeRecord

class UserType(str, Enum):
    PARENT = "parent"
    TEACHER = "teacher"
    ADMIN = "admin"

class User(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    username: str = Field(index=True)
    email: str = Field(unique=True, index=True)
    hashed_password: str
    full_name: str
    user_type: UserType
    active: bool = True
    created_at: datetime = Field(default_factory=datetime.now)
      # Relationships
    avisos: List["Aviso"] = Relationship(back_populates="author")
    children: List["ChildParentLink"] = Relationship(back_populates="parent")
    
class Child(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    name: str
    birth_date: datetime
    classroom: str
      # Relationships
    parents: List["ChildParentLink"] = Relationship(back_populates="child")
    rotinas: List["Rotina"] = Relationship(back_populates="child")
    saude_records: List["SaudeRecord"] = Relationship(back_populates="child")
    
class ChildParentLink(SQLModel, table=True):
    """Many-to-many relationship between children and parents"""
    parent_id: Optional[int] = Field(foreign_key="user.id", primary_key=True)
    child_id: Optional[int] = Field(foreign_key="child.id", primary_key=True)
    
    parent: User = Relationship(back_populates="children")
    child: Child = Relationship(back_populates="parents")