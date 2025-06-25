import pytest
from httpx import AsyncClient
from main import app

@pytest.mark.asyncio
async def test_login_and_protected_routes():
    async with AsyncClient(app=app, base_url="http://test") as ac:
        # Login
        response = await ac.post("/token", data={"username": "lucas", "password": "senha123"})
        assert response.status_code == 200
        token = response.json().get("access_token")
        assert token is not None

        headers = {"Authorization": f"Bearer {token}"}

        # /avisos
        res_avisos = await ac.get("/avisos", headers=headers)
        assert res_avisos.status_code in (200, 404)

        # /rotina
        res_rotina = await ac.get("/rotina", headers=headers)
        assert res_rotina.status_code in (200, 404)

        # /saude
        res_saude = await ac.get("/saude", headers=headers)
        assert res_saude.status_code in (200, 404)

        # /calendario
        res_calendario = await ac.get("/calendario", headers=headers)
        assert res_calendario.status_code in (200, 404)
