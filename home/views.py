from django.shortcuts import render
from home.models import HomePage
from django.db import connection

def get_homepage(request):
    # Potential SQL Injection Vulnerability: unsafe query concatenation
    page_title = request.GET.get('title', '')
    query = f"SELECT * FROM home_homepage WHERE title = '{page_title}'"
    with connection.cursor() as cursor:
        cursor.execute(query)
        page = cursor.fetchall()
    return render(request, 'home/homepage.html', {'page': page})