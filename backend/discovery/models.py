from django.db import models


class Venue(models.Model):
    CATEGORY_CHOICES = [
        ('restaurant', 'Restaurant'),
        ('lounge', 'Lounge'),
        ('billiard', 'Billiard Hall'),
        ('cafe', 'Café'),
        ('bar', 'Bar'),
        ('experience', 'Experience'),
    ]

    name = models.CharField(max_length=120)
    category = models.CharField(max_length=40, choices=CATEGORY_CHOICES)
    description = models.TextField()
    latitude = models.FloatField()
    longitude = models.FloatField()
    rating = models.FloatField(default=4.0)
    distance_km = models.FloatField(default=0.0)
    image_url = models.URLField(blank=True)

    def __str__(self) -> str:
        return self.name
