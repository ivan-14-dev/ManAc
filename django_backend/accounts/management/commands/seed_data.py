from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from departments.models import Department
from equipment.models import Equipment

User = get_user_model()


class Command(BaseCommand):
    help = 'Seeds the database with initial data'

    def handle(self, *args, **options):
        # Create departments
        departments_data = [
            {'name': 'Informatique', 'code': 'INF', 'description': 'Department of Computer Science'},
            {'name': 'Mathematiques', 'code': 'MAT', 'description': 'Department of Mathematics'},
            {'name': 'Physique', 'code': 'PHY', 'description': 'Department of Physics'},
            {'name': 'Chimie', 'code': 'CHM', 'description': 'Department of Chemistry'},
            {'name': 'Biologie', 'code': 'BIO', 'description': 'Department of Biology'},
            {'name': 'Administration', 'code': 'ADM', 'description': 'Administration Department'},
        ]
        
        for dept_data in departments_data:
            dept, created = Department.objects.get_or_create(
                code=dept_data['code'],
                defaults=dept_data
            )
            if created:
                self.stdout.write(f'Created department: {dept.name}')
        
        # Create general admin
        if not User.objects.filter(username='admin').exists():
            admin = User.objects.create_superuser(
                username='admin',
                email='admin@manac.com',
                password='admin123',
                first_name='Admin',
                last_name='User',
                role='general_admin'
            )
            self.stdout.write(f'Created superuser: {admin.username}')
        
        # Create department admin for INF
        inf_dept = Department.objects.get(code='INF')
        if not User.objects.filter(username='inf_admin').exists():
            inf_admin = User.objects.create_user(
                username='inf_admin',
                email='inf_admin@manac.com',
                password='admin123',
                first_name='INF',
                last_name='Admin',
                role='department_admin',
                department=inf_dept
            )
            self.stdout.write(f'Created department admin: {inf_admin.username}')
        
        # Create sample equipment
        equipment_data = [
            {'name': 'Projecteur Epson', 'category': 'projector', 'serial_number': 'PRJ-001', 'department': inf_dept, 'location': 'Salle 101', 'total_quantity': 2, 'value': 500.00},
            {'name': 'Ordinateur Dell', 'category': 'computer', 'serial_number': 'PC-001', 'department': inf_dept, 'location': 'Labo 1', 'total_quantity': 10, 'value': 800.00},
            {'name': 'Enceinte JBL', 'category': 'audio', 'serial_number': 'SPK-001', 'department': inf_dept, 'location': 'Salle 102', 'total_quantity': 5, 'value': 150.00},
        ]
        
        for eq_data in equipment_data:
            eq, created = Equipment.objects.get_or_create(
                serial_number=eq_data['serial_number'],
                defaults=eq_data
            )
            if created:
                self.stdout.write(f'Created equipment: {eq.name}')
        
        self.stdout.write(self.style.SUCCESS('Database seeded successfully!'))
        self.stdout.write('Login credentials:')
        self.stdout.write('  - General Admin: admin / admin123')
        self.stdout.write('  - Department Admin: inf_admin / admin123')
