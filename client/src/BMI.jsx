
function BMI({ height, weight }) {
    const heightInMetres = Number(height) / 100;
    const weightInKg = Number(weight);

    const validData =
        Number.isFinite(heightInMetres) &&
        Number.isFinite(weightInKg) &&
        heightInMetres > 0 &&
        weightInKg > 0;

    const bmi = validData
        ? weightInKg / (heightInMetres * heightInMetres)
        : null;

    let category = "";
    let description = "";
    let categoryColor = "#64748b";

    if (bmi !== null) {
        if (bmi < 18.5) {
            category = "Underweight";
            description = "Your BMI is below the standard adult healthy range.";
            categoryColor = "#d97706";
        } else if (bmi < 25) {
            category = "Normal weight";
            description = "Your BMI is within the standard adult healthy range.";
            categoryColor = "#059669";
        } else if (bmi < 30) {
            category = "Overweight";
            description = "Your BMI is above the standard adult healthy range.";
            categoryColor = "#d97706";
        } else {
            category = "Obesity";
            description = "Your BMI is in the obesity range. Consider discussing it with a healthcare professional.";
            categoryColor = "#dc2626";
        }
    }

    return (
        <section
            className="hm-panel"
            style={{ marginTop: "20px" }}
        >
            <h2>BMI Calculator</h2>

            <p style={{ color: "#64748b", marginBottom: "20px" }}>
                Your Body Mass Index based on your profile information.
            </p>

            {!validData ? (
                <p>
                    Please update your height and weight in your profile
                    to calculate BMI.
                </p>
            ) : (
                <>
                    <div
                        style={{
                            display: "flex",
                            flexWrap: "wrap",
                            gap: "30px",
                            alignItems: "center"
                        }}
                    >
                        <div>
                            <p style={{ color: "#64748b", margin: 0 }}>
                                Your BMI
                            </p>

                            <h1 style={{ fontSize: "42px", margin: "5px 0" }}>
                                {bmi.toFixed(1)}
                            </h1>
                        </div>

                        <div>
                            <p
                                style={{
                                    color: categoryColor,
                                    fontWeight: "bold",
                                    fontSize: "20px",
                                    margin: "0 0 8px"
                                }}
                            >
                                {category}
                            </p>

                            <p style={{ color: "#64748b", margin: 0 }}>
                                {description}
                            </p>
                        </div>
                    </div>

                    <div
                        style={{
                            display: "flex",
                            gap: "8px",
                            marginTop: "22px",
                            height: "12px",
                            borderRadius: "10px",
                            overflow: "hidden"
                        }}
                    >
                        <div style={{ flex: 1, background: "#60a5fa" }} />
                        <div style={{ flex: 1, background: "#34d399" }} />
                        <div style={{ flex: 1, background: "#fbbf24" }} />
                        <div style={{ flex: 1, background: "#f87171" }} />
                    </div>

                    <div
                        style={{
                            display: "flex",
                            justifyContent: "space-between",
                            flexWrap: "wrap",
                            gap: "8px",
                            fontSize: "12px",
                            color: "#64748b",
                            marginTop: "10px"
                        }}
                    >
                        <span>Below 18.5</span>
                        <span>18.5–24.9</span>
                        <span>25–29.9</span>
                        <span>30+</span>
                    </div>

                    <p
                        style={{
                            marginTop: "18px",
                            fontSize: "13px",
                            color: "#64748b"
                        }}
                    >
                        BMI is a screening measure, not a medical diagnosis.
                        Adult BMI categories are not intended for children.
                    </p>
                </>
            )}
        </section>
    );
}

export default BMI;
