import gitlab


from . import settings


def make_gitlab_client():
    gl = gitlab.Gitlab(settings.GITLAB_URL, private_token=settings.GITLAB_PRIVATE_TOKEN)
    gl.auth()
    return gl
