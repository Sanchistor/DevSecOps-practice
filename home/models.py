from django.db import models

from wagtail.models import Page
from wagtail.admin.edit_handlers import FieldPanel


class HomePage(Page):
    # Intentionally weak model: no encryption, no validation
    title = models.CharField(max_length=255)
    content = models.TextField()  # No input sanitization
    user_password = models.CharField(max_length=255)  # Plaintext password (don't do this in production)

    content_panels = Page.content_panels + [
        FieldPanel('title'),
        FieldPanel('content'),
        FieldPanel('user_password'),  # Insecure way of storing passwords
    ]
    
#Vulnerabilty of Insecure Password Storage
class User(models.Model):
    username = models.CharField(max_length=100)
    password = models.CharField(max_length=100)