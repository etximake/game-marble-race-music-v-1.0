import pytest
from src.domain.slicing import SlicePlan, SliceMode
from src.domain.errors import InvalidSlicePlanError

def test_valid_fixed_interval_plan():
    plan = SlicePlan(
        mode=SliceMode.FIXED_INTERVAL,
        fixed_interval_seconds=0.2
    )
    # Should not raise any error
    plan.validate()

def test_invalid_fixed_interval_plan():
    plan = SlicePlan(
        mode=SliceMode.FIXED_INTERVAL,
        fixed_interval_seconds=-0.5
    )
    with pytest.raises(InvalidSlicePlanError):
        plan.validate()

def test_valid_manual_markers_plan():
    plan = SlicePlan(
        mode=SliceMode.MANUAL_MARKERS,
        markers=[0.0, 0.5, 1.0, 1.5]
    )
    plan.validate()

def test_invalid_manual_markers_empty():
    plan = SlicePlan(
        mode=SliceMode.MANUAL_MARKERS,
        markers=[]
    )
    with pytest.raises(InvalidSlicePlanError):
        plan.validate()

def test_invalid_manual_markers_not_sorted():
    plan = SlicePlan(
        mode=SliceMode.MANUAL_MARKERS,
        markers=[0.0, 1.0, 0.5]
    )
    with pytest.raises(InvalidSlicePlanError):
        plan.validate()

def test_invalid_manual_markers_negative():
    plan = SlicePlan(
        mode=SliceMode.MANUAL_MARKERS,
        markers=[-0.5, 0.5, 1.0]
    )
    with pytest.raises(InvalidSlicePlanError):
        plan.validate()

def test_target_duration_must_fit_short_profile():
    plan = SlicePlan(mode=SliceMode.FIXED_INTERVAL, fixed_interval_seconds=0.2, target_duration_seconds=22.0)
    plan.validate()

def test_target_duration_cannot_exceed_short_profile():
    plan = SlicePlan(mode=SliceMode.FIXED_INTERVAL, fixed_interval_seconds=0.2, target_duration_seconds=31.0)
    with pytest.raises(InvalidSlicePlanError):
        plan.validate()
