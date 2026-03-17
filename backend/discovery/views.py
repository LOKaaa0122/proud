import json
from dataclasses import asdict, dataclass
from math import sqrt
from typing import Any

from django.http import HttpRequest, JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_GET, require_POST


@dataclass
class VenueData:
    id: int
    name: str
    category: str
    description: str
    latitude: float
    longitude: float
    rating: float
    distance_km: float


VENUES = [
    VenueData(1, 'Neon Lounge', 'lounge', 'Rooftop lounge with live DJs and skyline views.', 6.5244, 3.3792, 4.7, 1.2),
    VenueData(2, 'Cornerstone Café', 'cafe', 'Quiet artisanal coffee house with minimalist design.', 6.5211, 3.3678, 4.6, 0.8),
    VenueData(3, 'Rack & Roll', 'billiard', 'Modern billiard hall with gourmet street bites.', 6.5332, 3.3815, 4.5, 2.0),
    VenueData(4, 'Firewood Kitchen', 'restaurant', 'West-African fusion dining with open kitchen theater.', 6.5293, 3.3726, 4.8, 1.5),
    VenueData(5, 'Pulse Arena', 'experience', 'Immersive esports and VR social experience center.', 6.5364, 3.3741, 4.4, 2.3),
]


def _filter_venues(query: str | None, category: str | None) -> list[VenueData]:
    items = VENUES
    if category:
        items = [venue for venue in items if venue.category == category.lower()]
    if query:
        q = query.lower().strip()
        items = [
            venue
            for venue in items
            if q in venue.name.lower() or q in venue.description.lower() or q in venue.category.lower()
        ]
    return sorted(items, key=lambda v: (v.distance_km, -v.rating))


@require_GET
def venue_list(request: HttpRequest) -> JsonResponse:
    query = request.GET.get('query')
    category = request.GET.get('category')
    venues = [asdict(venue) for venue in _filter_venues(query, category)]
    return JsonResponse({'results': venues})


@require_POST
@csrf_exempt
def ai_assistant(request: HttpRequest) -> JsonResponse:
    payload: dict[str, Any] = json.loads(request.body.decode('utf-8') or '{}')
    prompt = payload.get('prompt', '').strip()
    user_lat = float(payload.get('latitude', 6.5244))
    user_lng = float(payload.get('longitude', 3.3792))

    ranked = sorted(
        VENUES,
        key=lambda venue: sqrt((venue.latitude - user_lat) ** 2 + (venue.longitude - user_lng) ** 2) - venue.rating * 0.01,
    )[:3]

    suggestions = [
        {
            'venue': venue.name,
            'category': venue.category,
            'direction': f"Head {(venue.latitude - user_lat) * 111:.1f} km north and {(venue.longitude - user_lng) * 111:.1f} km east.",
        }
        for venue in ranked
    ]

    reply = (
        f"You asked: '{prompt}'. Here are your top nearby matches with quick directions. "
        'I can refine this by vibe, budget, or crowd level.'
    )

    return JsonResponse({'reply': reply, 'suggestions': suggestions})
