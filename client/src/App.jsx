
import BMI from "./BMI";
import { useEffect, useMemo, useState } from "react";
import Login from "./Login";
import Register from "./Register";
import API from "./api";
import "./App.css";
import "./AppFeatures.css";

const pages = [
    ["dashboard", "Dashboard", "▦"],
    ["progress", "Progress", "↗"],
    ["wellness", "My Wellness", "♡"],
    ["notifications", "Notifications", "♧"],
    ["profile", "Profile", "◉"],
];

const dailyGoals = [
    {
        category: "water",
        title: "Water Intake",
        icon: "💧",
        target: 2.5,
        unit: "litres",
        color: "#269BCB",
        decimals: 2
    },
    {
        category: "sleep",
        title: "Sleep",
        icon: "😴",
        target: 8,
        unit: "hours",
        color: "#9875D0",
        decimals: 1
    },
    {
        category: "exercise",
        title: "Exercise",
        icon: "🏃",
        target: 30,
        unit: "minutes",
        color: "#299D75",
        decimals: 0
    }
];

function App() {
    const [token, setToken] = useState(localStorage.getItem("token"));
    const [showRegister, setShowRegister] = useState(false);
    const [activePage, setActivePage] = useState("dashboard");

    const [user, setUser] = useState(null);
    const [profileLoading, setProfileLoading] = useState(false);

    const [records, setRecords] = useState([]);
    const [loading, setLoading] = useState(false);
    const [saving, setSaving] = useState(false);

    const [error, setError] = useState("");
    const [message, setMessage] = useState("");

    const [category, setCategory] = useState("water");
    const [value, setValue] = useState("");
    const [unit, setUnit] = useState("litres");
    const [notes, setNotes] = useState("");
    const [editingId, setEditingId] = useState(null);

    // Fetch user profile
    const fetchProfile = async () => {
        try {
            setProfileLoading(true);

            const response = await API.get("/auth/profile");
            setUser(response.data?.user || null);
        } catch (err) {
            setError(
                err.response?.data?.message ||
                "Unable to load your profile."
            );
        } finally {
            setProfileLoading(false);
        }
    };

    // Fetch wellness records
    const fetchWellnessData = async () => {
        try {
            setLoading(true);
            setError("");

            const response = await API.get("/wellness");

            setRecords(
                Array.isArray(response.data) ? response.data : []
            );
        } catch (err) {
            setError(
                err.response?.data?.message ||
                "Unable to load wellness data."
            );
        } finally {
            setLoading(false);
        }
    };

    // Load data after login
    useEffect(() => {
        if (token) {
            fetchProfile();
            fetchWellnessData();
        }
    }, [token]);

    // All-time totals
    const totals = useMemo(() => ({
        water: records
            .filter(r => r.category === "water")
            .reduce((s, r) => s + Number(r.value || 0), 0),

        sleep: records
            .filter(r => r.category === "sleep")
            .reduce((s, r) => s + Number(r.value || 0), 0),

        exercise: records
            .filter(r => r.category === "exercise")
            .reduce((s, r) => s + Number(r.value || 0), 0),

    }), [records]);

    // Today's records
    const todayRecords = useMemo(() => {
        const today = new Date().toDateString();

        return records.filter(record => {
            const recordDate = new Date(
                record.date || record.createdAt
            );

            return (
                !Number.isNaN(recordDate.getTime()) &&
                recordDate.toDateString() === today
            );
        });
    }, [records]);

    // Today's category totals
    const dailyTotals = useMemo(() => ({
        water: todayRecords
            .filter(r => r.category === "water")
            .reduce((s, r) => s + Number(r.value || 0), 0),

        sleep: todayRecords
            .filter(r => r.category === "sleep")
            .reduce((s, r) => s + Number(r.value || 0), 0),

        exercise: todayRecords
            .filter(r => r.category === "exercise")
            .reduce((s, r) => s + Number(r.value || 0), 0),

    }), [todayRecords]);

    // Last seven days
    const lastSevenDays = useMemo(() => {
        const today = new Date();

        return Array.from({ length: 7 }, (_, index) => {
            const day = new Date(today);

            day.setHours(0, 0, 0, 0);
            day.setDate(today.getDate() - (6 - index));

            const count = records.filter(record => {
                const date = new Date(
                    record.date || record.createdAt
                );

                return (
                    !Number.isNaN(date.getTime()) &&
                    date.toDateString() === day.toDateString()
                );
            }).length;

            return {
                label: day.toLocaleDateString("en-IN", {
                    weekday: "short"
                }),
                count
            };
        });
    }, [records]);

    // Login
    const handleLogin = newToken => {
        localStorage.setItem("token", newToken);
        setToken(newToken);
    };

    // Reset form
    const resetForm = () => {
        setEditingId(null);
        setCategory("water");
        setValue("");
        setUnit("litres");
        setNotes("");
    };

    // Logout
    const handleLogout = () => {
        localStorage.removeItem("token");

        setToken(null);
        setUser(null);
        setRecords([]);

        setActivePage("dashboard");
        setShowRegister(false);
        setError("");
        setMessage("");

        resetForm();
    };

    // Change category
    const handleCategoryChange = event => {
        const selected = event.target.value;

        setCategory(selected);

        setUnit(
            selected === "water"
                ? "litres"
                : selected === "sleep"
                    ? "hours"
                    : "minutes"
        );
    };

    // Add or update wellness record
    const handleSubmit = async event => {
        event.preventDefault();

        setMessage("");
        setError("");

        const numericValue = Number(value);

        if (!Number.isFinite(numericValue) || numericValue < 0) {
            setError("Please enter a valid non-negative value.");
            return;
        }

        try {
            setSaving(true);

            const data = {
                category,
                value: numericValue,
                unit,
                notes
            };

            if (editingId) {
                await API.put(`/wellness/${editingId}`, data);
                setMessage("Wellness record updated successfully!");
            } else {
                await API.post("/wellness", data);
                setMessage("Wellness record added successfully!");
            }

            resetForm();
            await fetchWellnessData();

        } catch (err) {
            setError(
                err.response?.data?.message ||
                "Unable to save wellness record."
            );
        } finally {
            setSaving(false);
        }
    };

    // Edit record
    const handleEdit = record => {
        setEditingId(record._id);
        setCategory(record.category);
        setValue(String(record.value));
        setUnit(record.unit);
        setNotes(record.notes || "");

        setActivePage("dashboard");

        window.scrollTo({
            top: 0,
            behavior: "smooth"
        });
    };

    // Delete record
    const handleDelete = async id => {
        if (!window.confirm("Are you sure you want to delete this record?")) {
            return;
        }

        try {
            await API.delete(`/wellness/${id}`);

            setMessage("Wellness record deleted successfully!");
            setError("");

            await fetchWellnessData();

        } catch (err) {
            setError(
                err.response?.data?.message ||
                "Unable to delete wellness record."
            );
        }
    };

    // Login and registration pages
    if (!token) {
        return showRegister
            ? (
                <Register
                    onShowLogin={() => setShowRegister(false)}
                />
            )
            : (
                <Login
                    onLogin={handleLogin}
                    onShowRegister={() => setShowRegister(true)}
                />
            );
    }

    // Wellness records component
    const WellnessRecords = ({ limit }) => {
        const visibleRecords = limit
            ? records.slice(0, limit)
            : records;

        if (!visibleRecords.length) {
            return (
                <div className="hm-empty">
                    No wellness records yet. Add your first activity from the Dashboard.
                </div>
            );
        }

        return (
            <div className="hm-record-list">
                {visibleRecords.map(record => (
                    <article className="hm-record" key={record._id}>
                        <div className="hm-record-icon">
                            {record.category === "water"
                                ? "💧"
                                : record.category === "sleep"
                                    ? "😴"
                                    : "🏃"}
                        </div>

                        <div className="hm-record-info">
                            <strong>
                                {record.category.charAt(0).toUpperCase() +
                                    record.category.slice(1)}
                            </strong>

                            <span>
                                {record.value} {record.unit}
                            </span>

                            {record.notes && (
                                <small>{record.notes}</small>
                            )}

                            <small>
                                {new Date(
                                    record.date || record.createdAt
                                ).toLocaleString()}
                            </small>
                        </div>

                        <div className="hm-record-actions">
                            <button
                                type="button"
                                onClick={() => handleEdit(record)}
                            >
                                Edit
                            </button>

                            <button
                                type="button"
                                className="hm-danger"
                                onClick={() => handleDelete(record._id)}
                            >
                                Delete
                            </button>
                        </div>
                    </article>
                ))}
            </div>
        );
    };

    // Daily goal progress component
    const DailyGoals = () => {
        const completedCount = dailyGoals.filter(
            goal => dailyTotals[goal.category] >= goal.target
        ).length;

        return (
            <section className="hm-panel" style={{ marginBottom: "24px" }}>
                <div className="hm-section-heading">
                    <div>
                        <p className="hm-eyebrow">BUILD HEALTHY HABITS</p>
                        <h2>Today's Wellness Goals</h2>
                        <p style={{ color: "#777", marginTop: "5px" }}>
                            Small steps towards a healthier you.
                        </p>
                    </div>

                    <span className="hm-form-symbol">🎯</span>
                </div>

                <div style={{
                    display: "grid",
                    gridTemplateColumns: "repeat(auto-fit, minmax(190px, 1fr))",
                    gap: "18px",
                    marginTop: "22px"
                }}>
                    {dailyGoals.map(goal => {
                        const current = dailyTotals[goal.category];
                        const percentage = Math.min(
                            100,
                            Math.round((current / goal.target) * 100)
                        );

                        const completed = current >= goal.target;

                        return (
                            <div
                                key={goal.category}
                                style={{
                                    padding: "20px",
                                    borderRadius: "14px",
                                    background: "#f8fafc",
                                    border: "1px solid #edf0f4"
                                }}
                            >
                                <div style={{
                                    display: "flex",
                                    justifyContent: "space-between",
                                    alignItems: "center"
                                }}>
                                    <span style={{ fontSize: "25px" }}>
                                        {goal.icon}
                                    </span>

                                    {completed && (
                                        <span style={{
                                            color: "#23865d",
                                            fontSize: "12px",
                                            fontWeight: "700"
                                        }}>
                                            ✓ Completed
                                        </span>
                                    )}
                                </div>

                                <h3 style={{
                                    margin: "14px 0 6px",
                                    fontSize: "16px"
                                }}>
                                    {goal.title}
                                </h3>

                                <div style={{
                                    display: "flex",
                                    alignItems: "baseline",
                                    gap: "5px",
                                    marginBottom: "12px"
                                }}>
                                    <strong style={{
                                        fontSize: "23px",
                                        color: "#263449"
                                    }}>
                                        {current.toFixed(goal.decimals)}
                                    </strong>

                                    <span style={{
                                        color: "#777",
                                        fontSize: "13px"
                                    }}>
                                        / {goal.target} {goal.unit}
                                    </span>
                                </div>

                                <div style={{
                                    height: "9px",
                                    background: "#e7ebf0",
                                    borderRadius: "20px",
                                    overflow: "hidden"
                                }}>
                                    <div style={{
                                        height: "100%",
                                        width: `${percentage}%`,
                                        background: goal.color,
                                        borderRadius: "20px",
                                        transition: "width 0.3s ease"
                                    }} />
                                </div>

                                <p style={{
                                    marginTop: "9px",
                                    color: "#737d8b",
                                    fontSize: "12px"
                                }}>
                                    {percentage}% completed
                                </p>
                            </div>
                        );
                    })}
                </div>

                <div style={{
                    marginTop: "20px",
                    padding: "14px",
                    borderRadius: "10px",
                    background: "#f0f7f4",
                    color: "#267451",
                    fontSize: "14px"
                }}>
                    <strong>{completedCount} of 3 goals completed.</strong>
                    {" "}Keep going and take care of yourself!
                </div>
            </section>
        );
    };

    return (
        <div className="app-container hm-layout">

            {/* SIDEBAR */}
            <aside className="sidebar hm-sidebar">
                <h2>♡ HealthMate</h2>

                <p className="hm-sidebar-caption">
                    YOUR WELLNESS SPACE
                </p>

                {pages.map(([id, label, symbol]) => (
                    <button
                        key={id}
                        className={activePage === id ? "active" : ""}
                        onClick={() => {
                            setActivePage(id);
                            setMessage("");
                            setError("");
                        }}
                    >
                        <span className="hm-nav-icon">{symbol}</span>
                        {label}

                        {id === "notifications" && (
                            <span className="hm-nav-dot" />
                        )}
                    </button>
                ))}

                <button className="hm-logout" onClick={handleLogout}>
                    <span className="hm-nav-icon">↪</span>
                    Logout
                </button>
            </aside>

            {/* MAIN CONTENT */}
            <main className="dashboard hm-main">

                <div className="hm-topbar">
                    <span>Healthcare & Wellness Companion</span>

                    <button
                        type="button"
                        onClick={() => setActivePage("notifications")}
                    >
                        ♧ Notifications
                    </button>
                </div>

                {loading && (
                    <div className="hm-banner">
                        Loading wellness data...
                    </div>
                )}

                {profileLoading && (
                    <div className="hm-banner">
                        Loading your profile...
                    </div>
                )}

                {error && (
                    <div className="hm-banner hm-error">
                        {error}
                    </div>
                )}

                {message && (
                    <div className="hm-banner hm-success">
                        {message}
                    </div>
                )}

                {/* DASHBOARD */}
                {activePage === "dashboard" && (
                    <>
                        <div className="hm-page-heading">
                            <div>
                                <p className="hm-eyebrow">
                                    YOUR DAILY OVERVIEW
                                </p>

                                <h1>Wellness Dashboard</h1>

                                <p>
                                    Welcome back, {user?.name || "User"}!
                                    Keep building healthy habits, one day at a time.
                                </p>
                            </div>

                            <span className="hm-date">
                                {new Date().toLocaleDateString("en-IN", {
                                    day: "numeric",
                                    month: "short",
                                    year: "numeric"
                                })}
                            </span>
                        </div>

                        {/* ALL-TIME SUMMARY */}
                        <section className="hm-summary-grid">
                            <div className="hm-summary-card water">
                                <span>💧</span>
                                <p>Water intake (total)</p>
                                <h2>
                                    {totals.water.toFixed(2)}
                                    <small> litres</small>
                                </h2>
                            </div>

                            <div className="hm-summary-card sleep">
                                <span>😴</span>
                                <p>Sleep tracked (total)</p>
                                <h2>
                                    {totals.sleep.toFixed(1)}
                                    <small> hours</small>
                                </h2>
                            </div>

                            <div className="hm-summary-card exercise">
                                <span>🏃</span>
                                <p>Exercise (total)</p>
                                <h2>
                                    {Math.round(totals.exercise)}
                                    <small> minutes</small>
                                </h2>
                            </div>

                            <div className="hm-summary-card entries">
                                <span>📊</span>
                                <p>Total entries</p>
                                <h2>
                                    {records.length}
                                    <small> records</small>
                                </h2>
                            </div>
                        </section>

                        {/* DAILY GOALS */}
                        <DailyGoals />

                        {/* ADD WELLNESS FORM */}
                        <section className="wellness-form-section hm-form-section">
                            <div className="hm-section-heading">
                                <div>
                                    <p className="hm-eyebrow">
                                        TRACK YOUR HABITS
                                    </p>

                                    <h2>
                                        {editingId
                                            ? "Update Wellness Activity"
                                            : "Add Wellness Activity"}
                                    </h2>
                                </div>

                                <span className="hm-form-symbol">＋</span>
                            </div>

                            <form
                                onSubmit={handleSubmit}
                                className="wellness-form hm-form"
                            >
                                <div>
                                    <label>Activity</label>

                                    <select
                                        value={category}
                                        onChange={handleCategoryChange}
                                    >
                                        <option value="water">Water Intake</option>
                                        <option value="sleep">Sleep</option>
                                        <option value="exercise">Exercise</option>
                                    </select>
                                </div>

                                <div>
                                    <label>Value</label>

                                    <input
                                        type="number"
                                        min="0"
                                        step="any"
                                        placeholder="Enter value"
                                        value={value}
                                        onChange={e => setValue(e.target.value)}
                                        required
                                    />
                                </div>

                                <div>
                                    <label>Unit</label>

                                    <input
                                        type="text"
                                        value={unit}
                                        onChange={e => setUnit(e.target.value)}
                                        required
                                    />
                                </div>

                                <div>
                                    <label>Notes</label>

                                    <input
                                        type="text"
                                        placeholder="Optional notes"
                                        value={notes}
                                        onChange={e => setNotes(e.target.value)}
                                    />
                                </div>

                                <div className="hm-form-buttons">
                                    <button type="submit" disabled={saving}>
                                        {saving
                                            ? "Saving..."
                                            : editingId
                                                ? "Update Activity"
                                                : "Save Activity"}
                                    </button>

                                    {editingId && (
                                        <button
                                            type="button"
                                            className="hm-secondary"
                                            onClick={resetForm}
                                        >
                                            Cancel
                                        </button>
                                    )}
                                </div>
                            </form>
                        </section>

                        {/* RECENT RECORDS */}
                        <section className="wellness-history hm-recent">
                            <div className="hm-section-heading">
                                <h2>Recent Wellness Records</h2>

                                <button
                                    type="button"
                                    onClick={() => setActivePage("wellness")}
                                >
                                    View all →
                                </button>
                            </div>

                            <WellnessRecords limit={3} />
                        </section>
                    </>
                )}

                {/* PROGRESS */}
                {activePage === "progress" && (
                    <>
                        <div className="hm-page-heading">
                            <div>
                                <p className="hm-eyebrow">
                                    YOUR ACTIVITY HISTORY
                                </p>

                                <h1>Progress</h1>

                                <p>
                                    See the wellness activities you have recorded.
                                </p>
                            </div>
                        </div>

                        <section className="hm-summary-grid">
                            <div className="hm-summary-card water">
                                <span>💧</span>
                                <p>Total water</p>
                                <h2>{totals.water.toFixed(2)} <small>litres</small></h2>
                            </div>

                            <div className="hm-summary-card sleep">
                                <span>😴</span>
                                <p>Total sleep</p>
                                <h2>{totals.sleep.toFixed(1)} <small>hours</small></h2>
                            </div>

                            <div className="hm-summary-card exercise">
                                <span>🏃</span>
                                <p>Total exercise</p>
                                <h2>{Math.round(totals.exercise)} <small>minutes</small></h2>
                            </div>
                        </section>

                        <DailyGoals />

                        <section className="hm-panel">
                            <h2>Entries over the last 7 days</h2>

                            <div className="hm-chart">
                                {lastSevenDays.map(day => (
                                    <div
                                        className="hm-chart-column"
                                        key={day.label + day.count}
                                    >
                                        <strong>{day.count}</strong>

                                        <div className="hm-chart-track">
                                            <span
                                                style={{
                                                    height: `${Math.max(
                                                        6,
                                                        day.count /
                                                        Math.max(
                                                            1,
                                                            ...lastSevenDays.map(d => d.count)
                                                        ) * 100
                                                    )}%`
                                                }}
                                            />
                                        </div>

                                        <small>{day.label}</small>
                                    </div>
                                ))}
                            </div>

                            <p className="hm-chart-note">
                                Bars show the number of wellness records saved each day.
                            </p>
                        </section>

                        <section className="wellness-history">
                            <h2>All Wellness Records</h2>
                            <WellnessRecords />
                        </section>
                    </>
                )}

                {/* MY WELLNESS */}
                {activePage === "wellness" && (
                    <>
                        <div className="hm-page-heading">
                            <div>
                                <p className="hm-eyebrow">YOUR SAVED ACTIVITIES</p>
                                <h1>My Wellness</h1>
                                <p>
                                    Review, edit or remove your wellness entries.
                                </p>
                            </div>
                        </div>

                        <section className="hm-panel">
                            <div className="hm-section-heading">
                                <h2>All Wellness Records</h2>
                                <span>{records.length} entries</span>
                            </div>

                            <WellnessRecords />
                        </section>
                    </>
                )}

                {/* NOTIFICATIONS */}
                {activePage === "notifications" && (
                    <>
                        <div className="hm-page-heading">
                            <div>
                                <p className="hm-eyebrow">GENTLE DAILY GUIDANCE</p>
                                <h1>Notifications</h1>
                                <p>
                                    Helpful reminders for maintaining a balanced routine.
                                </p>
                            </div>
                        </div>

                        <section className="hm-panel hm-notices">
                            <article>
                                <span>💧</span>
                                <div>
                                    <h3>Stay hydrated</h3>
                                    <p>
                                        Drink water regularly throughout the day
                                        instead of waiting until you feel thirsty.
                                    </p>
                                </div>
                            </article>

                            <article>
                                <span>😴</span>
                                <div>
                                    <h3>Prioritise sleep</h3>
                                    <p>
                                        Try to maintain a consistent bedtime
                                        and wake-up time.
                                    </p>
                                </div>
                            </article>

                            <article>
                                <span>🚶</span>
                                <div>
                                    <h3>Take movement breaks</h3>
                                    <p>
                                        Stand up, stretch or walk briefly
                                        after long periods of sitting.
                                    </p>
                                </div>
                            </article>

                            <article>
                                <span>♡</span>
                                <div>
                                    <h3>Update your wellness</h3>
                                    <p>
                                        Record your water, sleep and exercise
                                        activities to keep your progress history useful.
                                    </p>
                                </div>
                            </article>

                            <p className="hm-chart-note">
                                These are in-app wellness tips.
                                Push notifications are not configured in this version.
                            </p>
                        </section>
                    </>
                )}

                {/* PROFILE */}
                {activePage === "profile" && (
                    <>
                        <div className="hm-page-heading">
                            <div>
                                <p className="hm-eyebrow">ACCOUNT</p>
                                <h1>My Profile</h1>
                                <p>
                                    View your personal and wellness information.
                                </p>
                            </div>
                        </div>

                        <section className="hm-panel hm-profile-card">
                            <div className="hm-avatar">♙</div>

                            <div>
                                <h2>{user?.name || "Loading profile..."}</h2>
                                <p>{user?.email || "Email unavailable"}</p>
                                <p>
                                    Your HealthMate account and wellness information.
                                </p>
                            </div>
                        </section>

                        <section className="hm-panel">
                            <h2>Personal Information</h2>

                            <div className="hm-profile-stats">
                                <p>
                                    <strong>{user?.age ?? "—"}</strong>
                                    <span>Age</span>
                                </p>

                                <p>
                                    <strong>{user?.gender || "—"}</strong>
                                    <span>Gender</span>
                                </p>

                                <p>
                                    <strong>
                                        {user?.height ? `${user.height} cm` : "—"}
                                    </strong>
                                    <span>Height</span>
                                </p>

                                <p>
                                    <strong>
                                        {user?.weight ? `${user.weight} kg` : "—"}
                                    </strong>
                                    <span>Current weight</span>
                                </p>

                                <p>
                                    <strong>
                                        {user?.targetWeight
                                            ? `${user.targetWeight} kg`
                                            : "—"}
                                    </strong>
                                    <span>Target weight</span>
                                </p>

                                <p>
                                    <strong>
                                        {user?.goal
                                            ? user.goal.charAt(0).toUpperCase() +
                                            user.goal.slice(1)
                                            : "—"}
                                    </strong>
                                    <span>Fitness goal</span>
                                </p>
                            </div>
                        </section>

                        {/* BMI CALCULATOR */}
                        <BMI
                            height={user?.height}
                            weight={user?.weight}
                        />

                        {/* WELLNESS SUMMARY */}
                        <section className="hm-panel">
                            <h2>Wellness Summary</h2>

                            <div className="hm-profile-stats">
                                <p>
                                    <strong>{records.length}</strong>
                                    <span>Total records</span>
                                </p>

                                <p>
                                    <strong>{totals.water.toFixed(2)} L</strong>
                                    <span>Water recorded</span>
                                </p>

                                <p>
                                    <strong>{totals.sleep.toFixed(1)} hrs</strong>
                                    <span>Sleep recorded</span>
                                </p>

                                <p>
                                    <strong>{Math.round(totals.exercise)} min</strong>
                                    <span>Exercise recorded</span>
                                </p>
                            </div>

                            <button
                                className="hm-logout-button"
                                onClick={handleLogout}
                            >
                                Log out
                            </button>
                        </section>
                    </>
                )}

            </main>
        </div>
    );
}

export default App;
