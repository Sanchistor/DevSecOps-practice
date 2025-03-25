from django.db import models

from wagtail.models import Page
from wagtail.fields import RichTextField



class HomePage(Page):
    content = RichTextField(blank=True)

    # A vulnerable method, accepting raw user input without sanitization (XSS)
    def get_content(self):
        return self.content  # No sanitization, risky for XSS