from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import IncomeViewSet, ExpenseViewSet, BudgetViewSet, RecurringTransactionViewSet

router = DefaultRouter()
router.register(r'incomes', IncomeViewSet, basename='income')
router.register(r'expenses', ExpenseViewSet, basename='expense')
router.register(r'budgets', BudgetViewSet, basename='budget')
router.register(r'recurring', RecurringTransactionViewSet, basename='recurring')

urlpatterns = [
    path('', include(router.urls)),
]
