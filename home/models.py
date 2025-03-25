from django.db import models

from wagtail.models import Page


class HomePage(Page):
    # Intentionally weak model: no encryption, no validation
    title = models.CharField(max_length=255, default="Default Title")
    content = models.TextField(default="defaultconstent")  # No input sanitization
    user_password = models.CharField(max_length=255, default="defaultpassword")  # Plaintext password (don't do this in production)
    
#Vulnerabilty of Insecure Password Storage
class User(models.Model):
    username = models.CharField(max_length=100)
    password = models.CharField(max_length=100, default="defaultpassword")