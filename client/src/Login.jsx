
import { useState } from "react";
import API from "./api";

function Login({ onLogin, onShowRegister }) {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  const handleLogin = async (e) => {
    e.preventDefault();
    setError("");

    if (!email.trim() || !password) {
      setError("Please enter your email and password.");
      return;
    }

    try {
      setLoading(true);

      const response = await API.post("/auth/login", {
        email: email.trim().toLowerCase(),
        password,
      });

      const token = response.data?.token;

      if (!token) {
        setError("Login response did not contain an authentication token.");
        return;
      }

      onLogin(token);
    } catch (err) {
      setError(
        err.response?.data?.message ||
        "Unable to login. Please check your credentials and try again."
      );
    } finally {
      setLoading(false);
    }
  };

  return (
    <main className="hm-auth-page">
      <section className="hm-auth-visual">
        <div className="hm-auth-brand">
          <div className="hm-brand-icon">H</div>
          <span>HealthMate</span>
        </div>

        <div className="hm-auth-hero">
          <span className="hm-auth-tag">YOUR HEALTH. YOUR JOURNEY.</span>

          <h1>
            A healthier life
            <br />
            starts with <span>you.</span>
          </h1>

          <p>
            Track your daily habits, understand your wellness patterns,
            and take small steps towards a healthier lifestyle.
          </p>

          <div className="hm-auth-highlights">
            <div>
              <span>01</span>
              <p>Track your wellness</p>
            </div>
            <div>
              <span>02</span>
              <p>Understand your progress</p>
            </div>
            <div>
              <span>03</span>
              <p>Build healthier habits</p>
            </div>
          </div>
        </div>

        <p className="hm-auth-footer">
          Healthcare & Wellness Companion
        </p>
      </section>

      <section className="hm-auth-content">
        <div className="hm-login-card">
          <div className="hm-mobile-brand">
            <div className="hm-brand-icon">H</div>
            <span>HealthMate</span>
          </div>

          <div className="hm-login-heading">
            <span className="hm-auth-tag">WELCOME BACK</span>
            <h2>Sign in to your account</h2>
            <p>
              Enter your details to continue your wellness journey.
            </p>
          </div>

          <form onSubmit={handleLogin} className="hm-login-form">
            <div className="hm-field">
              <label htmlFor="login-email">Email address</label>
              <input
                id="login-email"
                type="email"
                placeholder="you@example.com"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                autoComplete="email"
                required
              />
            </div>

            <div className="hm-field">
              <label htmlFor="login-password">Password</label>

              <div className="hm-password-field">
                <input
                  id="login-password"
                  type={showPassword ? "text" : "password"}
                  placeholder="Enter your password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  autoComplete="current-password"
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

            {error && (
              <div className="hm-login-error" role="alert">
                {error}
              </div>
            )}

            <button
              type="submit"
              className="hm-login-button"
              disabled={loading}
            >
              {loading ? "Signing in..." : "Sign in"}
              {!loading && <span>→</span>}
            </button>
          </form>

          <div className="hm-login-divider">
            <span>NEW TO HEALTHMATE?</span>
          </div>

          <button
            type="button"
            className="hm-register-button"
            onClick={onShowRegister}
          >
            Create an account
          </button>

          <p className="hm-login-security">
            Your wellness journey starts here.
          </p>
        </div>
      </section>
    </main>
  );
}

export default Login;
