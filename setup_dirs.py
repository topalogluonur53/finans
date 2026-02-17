import os

dirs = [
    "finans_app/lib/core/constants",
    "finans_app/lib/core/theme",
    "finans_app/lib/core/utils",
    "finans_app/lib/data/models",
    "finans_app/lib/data/repositories",
    "finans_app/lib/data/providers",
    "finans_app/lib/presentation/screens/auth",
    "finans_app/lib/presentation/screens/home",
    "finans_app/lib/presentation/screens/portfolio",
    "finans_app/lib/presentation/screens/finance",
    "finans_app/lib/presentation/screens/tools",
    "finans_app/lib/presentation/widgets",
    "finans_app/lib/routes",
]

for d in dirs:
    os.makedirs(d, exist_ok=True)
