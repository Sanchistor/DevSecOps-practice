from django.shortcuts import render
from home.models import HomePage
from django.db import connection
from django.views.decorators.csrf import csrf_exempt

def get_homepage(request):
    # Potential SQL Injection Vulnerability: unsafe query concatenation
    page_title = request.GET.get('title', '')
    query = f"SELECT * FROM home_homepage WHERE title = '{page_title}'"
    with connection.cursor() as cursor:
        cursor.execute(query)
        page = cursor.fetchall()
    return render(request, 'home/homepage.html', {'page': page})

#Potential Cross-Site Request Forgery (CSRF) Vulnerability
@csrf_exempt  
def submit_form(request):
    if request.method == 'POST':
        # Form submission logic here
        pass
    return render(request, 'home/form.html')

# Vulnerable to IDOR (Insecure Direct Object Reference)
def get_homepage_by_id(request, page_id):
    page = HomePage.objects.get(id=page_id)  # No access control checks
    return render(request, 'home/homepage_by_id.html', {'page': page})