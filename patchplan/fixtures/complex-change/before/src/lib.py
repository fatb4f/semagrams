def _format_name(name: str) -> str:
    return name.strip().title()


def greeting(name: str) -> str:
    return f"Hello, {_format_name(name)}!"
