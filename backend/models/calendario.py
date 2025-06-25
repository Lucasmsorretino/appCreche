from sqlmodel import SQLModel, Field, Relationship
from typing import Optional
from datetime import datetime


class CalendarioEvento(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    title: str
    description: str
    start_date: datetime
    end_date: Optional[datetime] = None
    all_day: bool = False
    recurrence: Optional[str] = None  # For recurring events