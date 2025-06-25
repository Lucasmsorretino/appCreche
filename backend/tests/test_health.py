import pytest
from httpx import AsyncClient
from main import app

@pytest.mark.asyncio
async def test_health():
    """Testa o endpoint /health"""
    async with AsyncClient(app=app, base_url="http://test") as ac:
        response = await ac.get("/health")
        assert response.status_code == 200
        data = response.json()
        assert data.get("status") == "healthy"
        assert "database" in data
