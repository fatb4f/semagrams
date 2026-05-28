from src.app import render_profile


def test_render_profile() -> None:
    assert render_profile(" ada ") == "Hello, Ada!"
