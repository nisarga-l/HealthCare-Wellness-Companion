import React, { useMemo } from "react";

function SmartInsights({ dailyTotals }) {
    const insights = useMemo(() => {
        const water = Number(dailyTotals?.water || 0);
        const sleep = Number(dailyTotals?.sleep || 0);
        const exercise = Number(dailyTotals?.exercise || 0);

        const hydrationPercentage = Math.min(
            100,
            Math.round((water / 2.5) * 100)
        );

        const sleepPercentage = Math.min(
            100,
            Math.round((sleep / 8) * 100)
        );

        const exercisePercentage = Math.min(
            100,
            Math.round((exercise / 30) * 100)
        );

        const results = [];

        // Hydration insight
        if (water === 0) {
            results.push({
                icon: "💧",
                title: "Hydration",
                status: "Not tracked yet",
                color: "#45b8e8",
                message:
                    "You haven't logged your water intake today. Start tracking your hydration to understand your daily habits.",
                recommendation:
                    "Start by logging your first glass of water.",
                progress: hydrationPercentage
            });
        } else if (water >= 2.5) {
            results.push({
                icon: "💧",
                title: "Hydration",
                status: "Daily goal reached",
                color: "#45b8e8",
                message:
                    `You've logged ${water.toFixed(2)} litres of water today and reached your hydration goal.`,
                recommendation:
                    "Keep maintaining a consistent hydration routine.",
                progress: hydrationPercentage
            });
        } else {
            const remaining = Math.max(0, 2.5 - water);

            results.push({
                icon: "💧",
                title: "Hydration",
                status: "Goal in progress",
                color: "#45b8e8",
                message:
                    `You've logged ${water.toFixed(2)} litres today. Your daily target is 2.5 litres.`,
                recommendation:
                    `Approximately ${remaining.toFixed(2)} litres remain to reach your current daily goal.`,
                progress: hydrationPercentage
            });
        }

        // Sleep insight
        if (sleep === 0) {
            results.push({
                icon: "😴",
                title: "Sleep",
                status: "Not tracked yet",
                color: "#a78bfa",
                message:
                    "No sleep duration has been recorded today.",
                recommendation:
                    "Log your sleep duration to monitor your sleeping routine.",
                progress: sleepPercentage
            });
        } else if (sleep >= 8) {
            results.push({
                icon: "😴",
                title: "Sleep",
                status: "Daily goal reached",
                color: "#a78bfa",
                message:
                    `You've recorded ${sleep.toFixed(1)} hours of sleep.`,
                recommendation:
                    "Continue maintaining a consistent sleep schedule.",
                progress: sleepPercentage
            });
        } else {
            results.push({
                icon: "😴",
                title: "Sleep",
                status: "Below your goal",
                color: "#a78bfa",
                message:
                    `You've recorded ${sleep.toFixed(1)} hours against your 8-hour tracking goal.`,
                recommendation:
                    "Consider prioritising adequate rest and a consistent bedtime.",
                progress: sleepPercentage
            });
        }

        // Activity insight
        if (exercise === 0) {
            results.push({
                icon: "🏃",
                title: "Physical Activity",
                status: "Not tracked yet",
                color: "#34d399",
                message:
                    "You haven't recorded any physical activity today.",
                recommendation:
                    "Consider a short walk, stretching session or another activity you enjoy.",
                progress: exercisePercentage
            });
        } else if (exercise >= 30) {
            results.push({
                icon: "🏃",
                title: "Physical Activity",
                status: "Daily goal reached",
                color: "#34d399",
                message:
                    `You've logged ${Math.round(exercise)} minutes of physical activity today.`,
                recommendation:
                    "Great job staying active. Continue choosing movement that feels comfortable for you.",
                progress: exercisePercentage
            });
        } else {
            const remaining = Math.max(0, 30 - exercise);

            results.push({
                icon: "🏃",
                title: "Physical Activity",
                status: "Goal in progress",
                color: "#34d399",
                message:
                    `You've logged ${Math.round(exercise)} minutes of activity today.`,
                recommendation:
                    `${remaining} more minutes would complete your current activity goal.`,
                progress: exercisePercentage
            });
        }

        return results;
    }, [dailyTotals]);

    const completedGoals = insights.filter(
        insight => insight.status === "Daily goal reached"
    ).length;

    const overallMessage =
        completedGoals === 3
            ? "Excellent! You've completed all three wellness tracking goals."
            : completedGoals === 2
                ? "You're doing well! Two of your wellness goals are complete."
                : completedGoals === 1
                    ? "Good progress! One wellness goal has been completed."
                    : "Build your wellness routine by tracking your daily habits.";

    return (
        <section className="hm-smart-insights">

            <div className="hm-insights-header">
                <div>
                    <p className="hm-eyebrow">PERSONALIZED WELLNESS</p>

                    <h2>Smart Health Insights</h2>

                    <p className="hm-insights-subtitle">
                        Insights generated from your wellness activities today.
                    </p>
                </div>

                <div className="hm-insights-badge">
                    ✦ Daily Analysis
                </div>
            </div>

            <div className="hm-insights-summary">
                <div className="hm-insights-summary-icon">
                    ✨
                </div>

                <div>
                    <strong>Your daily overview</strong>

                    <p>{overallMessage}</p>
                </div>
            </div>

            <div className="hm-insights-grid">
                {insights.map(insight => (
                    <article
                        className="hm-insight-card"
                        key={insight.title}
                    >
                        <div className="hm-insight-card-top">
                            <span className="hm-insight-icon">
                                {insight.icon}
                            </span>

                            <span
                                className="hm-insight-status"
                                style={{
                                    color: insight.color
                                }}
                            >
                                {insight.status}
                            </span>
                        </div>

                        <h3>{insight.title}</h3>

                        <p className="hm-insight-message">
                            {insight.message}
                        </p>

                        <div className="hm-insight-progress">
                            <div className="hm-insight-progress-label">
                                <span>Goal progress</span>

                                <strong>
                                    {insight.progress}%
                                </strong>
                            </div>

                            <div className="hm-insight-progress-track">
                                <div
                                    className="hm-insight-progress-fill"
                                    style={{
                                        width: `${insight.progress}%`,
                                        background: insight.color
                                    }}
                                />
                            </div>
                        </div>

                        <div className="hm-insight-recommendation">
                            <span>💡</span>

                            <p>
                                <strong>Recommendation:</strong>{" "}
                                {insight.recommendation}
                            </p>
                        </div>
                    </article>
                ))}
            </div>

            <div className="hm-insights-footer">
                <span>ⓘ</span>

                <p>
                    These insights are based on your logged activities
                    and personal tracking goals. They are wellness
                    suggestions, not medical advice.
                </p>
            </div>

        </section>
    );
}

export default SmartInsights;