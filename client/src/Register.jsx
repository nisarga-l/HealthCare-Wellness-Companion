
import { useState } from "react";
import API from "./api";

function Register({ onShowLogin }) {
    const [formData, setFormData] = useState({
        name: "",
        email: "",
        password: "",
        age: "",
        gender: "",
        height: "",
        weight: "",
        targetWeight: "",
        goal: ""
    });

    const [error, setError] = useState("");
    const [success, setSuccess] = useState("");
    const [loading, setLoading] = useState(false);
    const [showPassword, setShowPassword] = useState(false);

    const handleChange = (e) => {
        const { name, value } = e.target;

        setFormData((previous) => ({
            ...previous,
            [name]: value
        }));
    };

    const handleRegister = async (e) => {
        e.preventDefault();

        setError("");
        setSuccess("");

        if (Number(formData.age) < 13 || Number(formData.age) > 120) {
            setError("Please enter a valid age between 13 and 120.");
            return;
        }

        if (Number(formData.height) < 50 || Number(formData.height) > 250) {
            setError("Please enter a valid height in cm.");
            return;
        }

        if (Number(formData.weight) <= 0 || Number(formData.targetWeight) <= 0) {
            setError("Please enter valid current and target weights.");
            return;
        }

        setLoading(true);

        try {
            await API.post("/auth/register", {
                ...formData,
                age: Number(formData.age),
                height: Number(formData.height),
                weight: Number(formData.weight),
                targetWeight: Number(formData.targetWeight)
            });

            setSuccess("Account created successfully! Please login.");

            setFormData({
                name: "",
                email: "",
                password: "",
                age: "",
                gender: "",
                height: "",
                weight: "",
                targetWeight: "",
                goal: ""
            });

        } catch (err) {
            setError(
                err.response?.data?.message ||
                "Registration failed. Please try again."
            );
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="hm-auth-page">

            <div className="hm-auth-visual">
                <div className="hm-auth-brand">
                    <div className="hm-brand-icon">H</div>
                    HealthMate
                </div>

                <div className="hm-auth-hero">
                    <span className="hm-auth-tag">YOUR PERSONAL WELLNESS COMPANION</span>

                    <h1>
                        Build healthier habits.
                        <span> Live better.</span>
                    </h1>

                    <p>
                        Track your daily activities, understand your progress
                        and build a healthier lifestyle with HealthMate.
                    </p>

                    <div className="hm-auth-highlights">
                        <div>
                            <span>01</span>
                            <p>Track your daily health activities</p>
                        </div>
                        <div>
                            <span>02</span>
                            <p>Monitor your fitness progress</p>
                        </div>
                        <div>
                            <span>03</span>
                            <p>Build habits around your personal goals</p>
                        </div>
                    </div>
                </div>

                <div className="hm-auth-footer">
                    Your health journey starts here.
                </div>
            </div>

            <div className="hm-auth-content">
                <div className="hm-login-card hm-register-card">

                    <div className="hm-mobile-brand">
                        <div className="hm-brand-icon">H</div>
                        HealthMate
                    </div>

                    <div className="hm-register-heading">
                        <span className="hm-auth-tag">GET STARTED</span>
                        <h2>Create your account</h2>
                        <p>
                            Tell us a little about yourself so we can
                            personalize your wellness journey.
                        </p>
                    </div>

                    <form
                        className="hm-register-form"
                        onSubmit={handleRegister}
                    >
                        <h3 className="hm-register-section-title">
                            PERSONAL INFORMATION
                        </h3>

                        <div className="hm-field">
                            <label>Full Name</label>
                            <input
                                type="text"
                                name="name"
                                placeholder="Enter your full name"
                                value={formData.name}
                                onChange={handleChange}
                                required
                            />
                        </div>

                        <div className="hm-field">
                            <label>Email Address</label>
                            <input
                                type="email"
                                name="email"
                                placeholder="Enter your email"
                                value={formData.email}
                                onChange={handleChange}
                                required
                            />
                        </div>

                        <div className="hm-field">
                            <label>Password</label>
                            <div className="hm-password-field">
                                <input
                                    type={showPassword ? "text" : "password"}
                                    name="password"
                                    placeholder="Minimum 6 characters"
                                    value={formData.password}
                                    onChange={handleChange}
                                    minLength={6}
                                    required
                                />
                                <button
                                    type="button"
                                    className="hm-password-toggle"
                                    onClick={() => setShowPassword(!showPassword)}
                                >
                                    {showPassword ? "Hide" : "Show"}
                                </button>
                            </div>
                        </div>

                        <h3 className="hm-register-section-title">
                            HEALTH PROFILE
                        </h3>

                        <div className="hm-field">
                            <label>Age</label>
                            <input
                                type="number"
                                name="age"
                                placeholder="Your age"
                                value={formData.age}
                                onChange={handleChange}
                                min="13"
                                max="120"
                                required
                            />
                        </div>

                        <div className="hm-field">
                            <label>Gender</label>
                            <select
                                name="gender"
                                value={formData.gender}
                                onChange={handleChange}
                                required
                            >
                                <option value="">Select gender</option>
                                <option value="Male">Male</option>
                                <option value="Female">Female</option>
                                <option value="Other">Other</option>
                                <option value="Prefer not to say">
                                    Prefer not to say
                                </option>
                            </select>
                        </div>

                        <div className="hm-field">
                            <label>Height (cm)</label>
                            <input
                                type="number"
                                name="height"
                                placeholder="e.g. 170"
                                value={formData.height}
                                onChange={handleChange}
                                min="50"
                                max="250"
                                required
                            />
                        </div>

                        <div className="hm-field">
                            <label>Current Weight (kg)</label>
                            <input
                                type="number"
                                name="weight"
                                placeholder="e.g. 70"
                                value={formData.weight}
                                onChange={handleChange}
                                min="1"
                                max="500"
                                step="0.1"
                                required
                            />
                        </div>

                        <div className="hm-field">
                            <label>Target Weight (kg)</label>
                            <input
                                type="number"
                                name="targetWeight"
                                placeholder="Your target weight"
                                value={formData.targetWeight}
                                onChange={handleChange}
                                min="1"
                                max="500"
                                step="0.1"
                                required
                            />
                        </div>

                        <div className="hm-field">
                            <label>Fitness Goal</label>
                            <select
                                name="goal"
                                value={formData.goal}
                                onChange={handleChange}
                                required
                            >
                                <option value="">Select your goal</option>
                                <option value="lose">Lose Weight</option>
                                <option value="gain">Gain Weight</option>
                                <option value="maintain">Maintain Weight</option>
                            </select>
                        </div>

                        {error && (
                            <div className="hm-register-error">
                                {error}
                            </div>
                        )}

                        {success && (
                            <div className="hm-register-success">
                                {success}
                            </div>
                        )}

                        <button
                            type="submit"
                            className="hm-register-submit"
                            disabled={loading}
                        >
                            {loading ? "Creating Account..." : "Create Account"}
                        </button>
                    </form>

                    <div className="hm-login-divider">
                        ALREADY HAVE AN ACCOUNT?
                    </div>

                    <button
                        type="button"
                        className="hm-register-button"
                        onClick={onShowLogin}
                    >
                        Login to HealthMate
                    </button>

                    <p className="hm-login-security">
                        Your health information is associated with your account.
                    </p>

                </div>
            </div>
        </div>
    );
}

export default Register;
