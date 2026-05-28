from src.app import render_user


def test_render_user() -> None:
    assert render_user(" ada ") == "Hello, Ada!"
