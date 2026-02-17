from django.contrib.auth.models import AbstractUser
from django.db import models

class CustomUser(AbstractUser):
    # Add any additional fields here if needed
    # user uses email for login usually in modern apps, but AbstractUser uses username.
    # We can keep it simple or customize.
    # The requirement says: login/register with JWT.
    # "Test kullanıcı girişi (demo: test@test.com / 123456)" implies email login or username='test@test.com'.
    
    email = models.EmailField(unique=True)

    # We might want to make email the USERNAME_FIELD, but for simplicity we can keep username
    # or just use email. Let's stick to default AbstractUser but ensure email is unique.
    
    def __str__(self):
        return self.username
