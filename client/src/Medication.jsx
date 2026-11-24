import React, { useEffect, useState } from "react";
import API from "./api";
import "./Medication.css";

function Medication() {
    const [medications, setMedications] = useState([]);
    const [loading, setLoading] = useState(true);
    const [showForm, setShowForm] = useState(false);
    const [error, setError] = useState("");
    const [success, setSuccess] = useState("");

    const [formData, setFormData] = useState({
        medicationName: "",
        dosage: "",
        instructions: "",
        frequency: "Daily",
        reminderTimes: ["09:00"],
        startDate: new Date().toISOString().split("T")[0],
        endDate: "",
        notes: ""
    });

    // Fetch medications
    const fetchMedications = async () => {
        try {
            setLoading(true);

            const response = await API.get("/medications");

            setMedications(response.data.medications || []);
            setError("");
        } catch (err) {
            console.error("Fetch medications error:", err);

            setError(
                err.response?.data?.message ||
                "Unable to load medications. Please try again."
            );
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchMedications();
    }, []);

    // Form input handler
    const handleChange = (e) => {
        const { name, value } = e.target;

        setFormData(prev => ({
            ...prev,
            [name]: value
        }));
    };

    // Reminder time handler
    const handleTimeChange = (index, value) => {
        setFormData(prev => {
            const updatedTimes = [...prev.reminderTimes];
            updatedTimes[index] = value;

            return {
                ...prev,
                reminderTimes: updatedTimes
            };
        });
    };

    const addReminderTime = () => {
        setFormData(prev => ({
            ...prev,
            reminderTimes: [...prev.reminderTimes, "18:00"]
        }));
    };

    const removeReminderTime = (index) => {
        setFormData(prev => ({
            ...prev,
            reminderTimes: prev.reminderTimes.filter(
                (_, i) => i !== index
            )
        }));
    };

    // Add medication
    const handleSubmit = async (e) => {
        e.preventDefault();

        try {
            setError("");
            setSuccess("");

            const payload = {
                ...formData,
                reminderTimes: formData.reminderTimes.filter(Boolean),
                endDate: formData.endDate || null
            };

            await API.post("/medications", payload);

            setSuccess("Medication added successfully!");

            setFormData({
                medicationName: "",
                dosage: "",
                instructions: "",
                frequency: "Daily",
                reminderTimes: ["09:00"],
                startDate: new Date().toISOString().split("T")[0],
                endDate: "",
                notes: ""
            });

            setShowForm(false);

            await fetchMedications();
        } catch (err) {
            console.error("Add medication error:", err);

            setError(
                err.response?.data?.message ||
                "Failed to add medication."
            );
        }
    };

    // Delete medication
    const handleDelete = async (id) => {
        const confirmed = window.confirm(
            "Are you sure you want to delete this medication?"
        );

        if (!confirmed) return;

        try {
            await API.delete(`/medications/${id}`);

            setSuccess("Medication deleted successfully!");

            await fetchMedications();
        } catch (err) {
            setError(
                err.response?.data?.message ||
                "Failed to delete medication."
            );
        }
    };

    // Toggle medication active status
    const toggleActive = async (medication) => {
        try {
            await API.put(`/medications/${medication._id}`, {
                isActive: !medication.isActive
            });

            await fetchMedications();
        } catch (err) {
            setError(
                err.response?.data?.message ||
                "Failed to update medication."
            );
        }
    };

    const activeMedications = medications.filter(
        medication => medication.isActive
    );

    const inactiveMedications = medications.filter(
        medication => !medication.isActive
    );

    const formatTime = (time) => {
        if (!time) return "";

        const [hours, minutes] = time.split(":");
        const hour = parseInt(hours, 10);

        const suffix = hour >= 12 ? "PM" : "AM";
        const formattedHour = hour % 12 || 12;

        return `${formattedHour}:${minutes} ${suffix}`;
    };

    const getTimeIcon = (time) => {
        const hour = parseInt(time?.split(":")[0] || "0", 10);

        if (hour >= 5 && hour < 12) return "☀️";
        if (hour >= 12 && hour < 17) return "🌤️";
        if (hour >= 17 && hour < 21) return "🌆";

        return "🌙";
    };

    return (
        <div className="medication-page">

            {/* PAGE HEADER */}
            <div className="medication-header">
                <div>
                    <p className="medication-eyebrow">
                        HEALTH MANAGEMENT
                    </p>

                    <h1>Medication & Reminders</h1>

                    <p className="medication-subtitle">
                        Manage your medications and keep track of your schedule.
                    </p>
                </div>

                <button
                    className="medication-add-button"
                    onClick={() => setShowForm(!showForm)}
                >
                    {showForm ? "✕ Cancel" : "+ Add Medication"}
                </button>
            </div>

            {/* MESSAGES */}
            {error && (
                <div className="medication-alert medication-error">
                    ⚠️ {error}
                </div>
            )}

            {success && (
                <div className="medication-alert medication-success">
                    ✓ {success}
                </div>
            )}

            {/* STATISTICS */}
            <div className="medication-stats">

                <div className="medication-stat-card">
                    <div className="medication-stat-icon purple">
                        💊
                    </div>

                    <div>
                        <p>Total Medications</p>
                        <h2>{medications.length}</h2>
                    </div>
                </div>

                <div className="medication-stat-card">
                    <div className="medication-stat-icon green">
                        ✓
                    </div>

                    <div>
                        <p>Active Medications</p>
                        <h2>{activeMedications.length}</h2>
                    </div>
                </div>

                <div className="medication-stat-card">
                    <div className="medication-stat-icon blue">
                        ⏰
                    </div>

                    <div>
                        <p>Scheduled Reminders</p>
                        <h2>
                            {activeMedications.reduce(
                                (total, medication) =>
                                    total +
                                    (medication.reminderTimes?.length || 0),
                                0
                            )}
                        </h2>
                    </div>
                </div>

                <div className="medication-stat-card">
                    <div className="medication-stat-icon orange">
                        📅
                    </div>

                    <div>
                        <p>Currently Active</p>
                        <h2>{activeMedications.length}</h2>
                    </div>
                </div>

            </div>

            {/* ADD MEDICATION FORM */}
            {showForm && (
                <section className="medication-form-panel">

                    <div className="medication-form-header">
                        <div>
                            <h2>Add New Medication</h2>

                            <p>
                                Enter medication details and schedule.
                            </p>
                        </div>
                    </div>

                    <form onSubmit={handleSubmit}>

                        <div className="medication-form-grid">

                            <div className="medication-form-group">
                                <label>Medication Name *</label>

                                <input
                                    type="text"
                                    name="medicationName"
                                    value={formData.medicationName}
                                    onChange={handleChange}
                                    placeholder="e.g. Vitamin D"
                                    required
                                />
                            </div>

                            <div className="medication-form-group">
                                <label>Dosage *</label>

                                <input
                                    type="text"
                                    name="dosage"
                                    value={formData.dosage}
                                    onChange={handleChange}
                                    placeholder="e.g. 1 tablet / 500 mg"
                                    required
                                />
                            </div>

                            <div className="medication-form-group">
                                <label>Frequency</label>

                                <select
                                    name="frequency"
                                    value={formData.frequency}
                                    onChange={handleChange}
                                >
                                    <option value="Daily">Daily</option>
                                    <option value="Twice daily">Twice daily</option>
                                    <option value="Three times daily">
                                        Three times daily
                                    </option>
                                    <option value="Weekly">Weekly</option>
                                    <option value="As needed">As needed</option>
                                    <option value="Custom">Custom</option>
                                </select>
                            </div>

                            <div className="medication-form-group">
                                <label>Instructions</label>

                                <select
                                    name="instructions"
                                    value={formData.instructions}
                                    onChange={handleChange}
                                >
                                    <option value="">Select instructions</option>
                                    <option value="Before food">Before food</option>
                                    <option value="After food">After food</option>
                                    <option value="With food">With food</option>
                                    <option value="With water">With water</option>
                                    <option value="No specific instructions">
                                        No specific instructions
                                    </option>
                                </select>
                            </div>

                            <div className="medication-form-group">
                                <label>Start Date *</label>

                                <input
                                    type="date"
                                    name="startDate"
                                    value={formData.startDate}
                                    onChange={handleChange}
                                    required
                                />
                            </div>

                            <div className="medication-form-group">
                                <label>End Date</label>

                                <input
                                    type="date"
                                    name="endDate"
                                    value={formData.endDate}
                                    onChange={handleChange}
                                />
                            </div>

                        </div>

                        {/* REMINDER TIMES */}
                        <div className="medication-reminder-section">

                            <label className="medication-section-label">
                                ⏰ Reminder Times
                            </label>

                            {formData.reminderTimes.map((time, index) => (
                                <div
                                    className="medication-time-row"
                                    key={index}
                                >
                                    <input
                                        type="time"
                                        value={time}
                                        onChange={(e) =>
                                            handleTimeChange(
                                                index,
                                                e.target.value
                                            )
                                        }
                                    />

                                    {formData.reminderTimes.length > 1 && (
                                        <button
                                            type="button"
                                            className="medication-remove-time"
                                            onClick={() =>
                                                removeReminderTime(index)
                                            }
                                        >
                                            Remove
                                        </button>
                                    )}
                                </div>
                            ))}

                            <button
                                type="button"
                                className="medication-add-time"
                                onClick={addReminderTime}
                            >
                                + Add another reminder time
                            </button>

                        </div>

                        <div className="medication-form-group medication-notes">
                            <label>Additional Notes</label>

                            <textarea
                                name="notes"
                                value={formData.notes}
                                onChange={handleChange}
                                placeholder="Additional instructions..."
                                rows={3}
                            />
                        </div>

                        <div className="medication-form-actions">
                            <button
                                type="button"
                                className="medication-cancel-button"
                                onClick={() => setShowForm(false)}
                            >
                                Cancel
                            </button>

                            <button
                                type="submit"
                                className="medication-submit-button"
                            >
                                Save Medication
                            </button>
                        </div>

                    </form>
                </section>
            )}

            {/* MEDICATION LIST */}
            <section className="medication-list-section">

                <div className="medication-section-heading">
                    <div>
                        <h2>Your Medications</h2>

                        <p>
                            Manage your medication details and reminder schedules.
                        </p>
                    </div>

                    <span className="medication-count">
                        {activeMedications.length} Active
                    </span>
                </div>

                {loading ? (
                    <div className="medication-loading">
                        <div className="medication-spinner"></div>
                        <p>Loading medications...</p>
                    </div>
                ) : activeMedications.length === 0 ? (
                    <div className="medication-empty">

                        <div className="medication-empty-icon">
                            💊
                        </div>

                        <h3>No medications added yet</h3>

                        <p>
                            Add your medications to organize your schedule
                            and reminders in one place.
                        </p>

                        <button
                            className="medication-add-button"
                            onClick={() => setShowForm(true)}
                        >
                            + Add Your First Medication
                        </button>

                    </div>
                ) : (
                    <div className="medication-cards-grid">

                        {activeMedications.map(medication => (
                            <article
                                className="medication-card"
                                key={medication._id}
                            >

                                <div className="medication-card-header">

                                    <div className="medication-card-icon">
                                        💊
                                    </div>

                                    <div className="medication-card-menu">
                                        <button
                                            title="Deactivate medication"
                                            onClick={() =>
                                                toggleActive(medication)
                                            }
                                        >
                                            ⋮
                                        </button>
                                    </div>

                                </div>

                                <h3>{medication.medicationName}</h3>

                                <p className="medication-dosage">
                                    {medication.dosage}
                                </p>

                                <div className="medication-detail-row">
                                    <span>Frequency</span>
                                    <strong>{medication.frequency}</strong>
                                </div>

                                {medication.instructions && (
                                    <div className="medication-detail-row">
                                        <span>Instructions</span>
                                        <strong>
                                            {medication.instructions}
                                        </strong>
                                    </div>
                                )}

                                <div className="medication-detail-row">
                                    <span>Start Date</span>
                                    <strong>
                                        {new Date(
                                            medication.startDate
                                        ).toLocaleDateString()}
                                    </strong>
                                </div>

                                {medication.endDate && (
                                    <div className="medication-detail-row">
                                        <span>End Date</span>
                                        <strong>
                                            {new Date(
                                                medication.endDate
                                            ).toLocaleDateString()}
                                        </strong>
                                    </div>
                                )}

                                {/* REMINDER SCHEDULE */}
                                <div className="medication-schedule">

                                    <p className="medication-schedule-title">
                                        ⏰ Reminder Schedule
                                    </p>

                                    {medication.reminderTimes?.length > 0 ? (
                                        <div className="medication-times">

                                            {medication.reminderTimes.map(
                                                (time, index) => (
                                                    <span
                                                        className="medication-time-chip"
                                                        key={index}
                                                    >
                                                        {getTimeIcon(time)}{" "}
                                                        {formatTime(time)}
                                                    </span>
                                                )
                                            )}

                                        </div>
                                    ) : (
                                        <p className="medication-no-times">
                                            No reminder times configured
                                        </p>
                                    )}

                                </div>

                                {medication.notes && (
                                    <div className="medication-notes-display">
                                        📝 {medication.notes}
                                    </div>
                                )}

                                <div className="medication-card-footer">

                                    <span className="medication-active-badge">
                                        ● Active
                                    </span>

                                    <button
                                        className="medication-delete-button"
                                        onClick={() =>
                                            handleDelete(medication._id)
                                        }
                                    >
                                        Delete
                                    </button>

                                </div>

                            </article>
                        ))}

                    </div>
                )}

            </section>

            {/* INACTIVE MEDICATIONS */}
            {inactiveMedications.length > 0 && (
                <section className="medication-inactive-section">

                    <h2>Inactive Medications</h2>

                    <div className="medication-inactive-list">

                        {inactiveMedications.map(medication => (
                            <div
                                className="medication-inactive-card"
                                key={medication._id}
                            >
                                <div>
                                    <strong>{medication.medicationName}</strong>
                                    <p>{medication.dosage}</p>
                                </div>

                                <button
                                    onClick={() => toggleActive(medication)}
                                >
                                    Reactivate
                                </button>

                                <button
                                    className="medication-delete-button"
                                    onClick={() =>
                                        handleDelete(medication._id)
                                    }
                                >
                                    Delete
                                </button>
                            </div>
                        ))}

                    </div>

                </section>
            )}

        </div>
    );
}

export default Medication;