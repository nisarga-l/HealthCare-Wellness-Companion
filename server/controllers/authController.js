
const User = require("../models/user");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const crypto = require("crypto");

// ==============================
// REGISTER USER
// ==============================
const registerUser = async (req, res) => {
    try {
        const {
            name,
            email,
            password,
            age,
            gender,
            height,
            weight,
            targetWeight,
            goal
        } = req.body;

        if (!name || !email || !password) {
            return res.status(400).json({
                message: "Name, email and password are required"
            });
        }

        if (password.length < 6) {
            return res.status(400).json({
                message: "Password must contain at least 6 characters"
            });
        }

        if (goal && !["lose", "gain", "maintain"].includes(goal)) {
            return res.status(400).json({
                message: "Invalid fitness goal"
            });
        }

        const normalizedEmail = email.trim().toLowerCase();

        const existingUser = await User.findOne({
            email: normalizedEmail
        });

        if (existingUser) {
            return res.status(400).json({
                message: "Email already registered"
            });
        }

        const hashedPassword = await bcrypt.hash(password, 10);

        const user = await User.create({
            name: name.trim(),
            email: normalizedEmail,
            password: hashedPassword,
            age,
            gender,
            height,
            weight,
            targetWeight,
            goal
        });

        return res.status(201).json({
            message: "Registration successful",
            user: {
                id: user._id,
                name: user.name,
                email: user.email,
                age: user.age,
                gender: user.gender,
                height: user.height,
                weight: user.weight,
                targetWeight: user.targetWeight,
                goal: user.goal
            }
        });

    } catch (error) {
        console.error("Registration Error:", error);

        if (error.name === "ValidationError") {
            return res.status(400).json({
                message: error.message
            });
        }

        return res.status(500).json({
            message: "Registration failed"
        });
    }
};


// ==============================
// LOGIN USER
// ==============================
const loginUser = async (req, res) => {
    try {
        const { email, password } = req.body;

        if (!email || !password) {
            return res.status(400).json({
                message: "Email and password are required"
            });
        }

        const normalizedEmail = email.trim().toLowerCase();

        const user = await User.findOne({
            email: normalizedEmail
        });

        if (!user) {
            return res.status(401).json({
                message: "Invalid email or password"
            });
        }

        const isMatch = await bcrypt.compare(
            password,
            user.password
        );

        if (!isMatch) {
            return res.status(401).json({
                message: "Invalid email or password"
            });
        }

        if (!process.env.JWT_SECRET) {
            console.error("JWT_SECRET is missing");

            return res.status(500).json({
                message: "Server authentication configuration error"
            });
        }

        const token = jwt.sign(
            { id: user._id },
            process.env.JWT_SECRET,
            { expiresIn: "7d" }
        );

        return res.status(200).json({
            message: "Login successful",
            token,
            user: {
                id: user._id,
                name: user.name,
                email: user.email,
                age: user.age,
                gender: user.gender,
                height: user.height,
                weight: user.weight,
                targetWeight: user.targetWeight,
                goal: user.goal
            }
        });

    } catch (error) {
        console.error("Login Error:", error);

        return res.status(500).json({
            message: "Login failed"
        });
    }
};


// ==============================
// FORGOT PASSWORD - DEMO OTP
// ==============================
const forgotPassword = async (req, res) => {
    try {
        const { email } = req.body;

        if (!email) {
            return res.status(400).json({
                message: "Email is required"
            });
        }

        const normalizedEmail = email.trim().toLowerCase();

        const user = await User.findOne({
            email: normalizedEmail
        });

        if (!user) {
            return res.status(404).json({
                message: "No account found with this email"
            });
        }

        // Generate a secure six-digit OTP
        const otp = crypto.randomInt(100000, 1000000).toString();

        // OTP expires after 10 minutes
        user.resetOtp = otp;
        user.resetOtpExpiry = new Date(
            Date.now() + 10 * 60 * 1000
        );

        await user.save();

        // DEMO ONLY: Return OTP to the Flutter app.
        // Do not expose OTPs this way in production.
        return res.status(200).json({
            message: "Demo OTP generated successfully",
            demoOtp: otp,
            expiresInMinutes: 10
        });

    } catch (error) {
        console.error("Forgot Password Error:", error);

        return res.status(500).json({
            message: "Unable to generate OTP"
        });
    }
};


// ==============================
// RESET PASSWORD
// ==============================
const resetPassword = async (req, res) => {
    try {
        const { email, otp, newPassword } = req.body;

        if (!email || !otp || !newPassword) {
            return res.status(400).json({
                message: "Email, OTP and new password are required"
            });
        }

        if (newPassword.length < 6) {
            return res.status(400).json({
                message: "Password must contain at least 6 characters"
            });
        }

        const normalizedEmail = email.trim().toLowerCase();

        const user = await User.findOne({
            email: normalizedEmail
        });

        if (
            !user ||
            !user.resetOtp ||
            !user.resetOtpExpiry
        ) {
            return res.status(400).json({
                message: "Please request a new OTP"
            });
        }

        // Check expiry
        if (user.resetOtpExpiry.getTime() < Date.now()) {
            user.resetOtp = null;
            user.resetOtpExpiry = null;

            await user.save();

            return res.status(400).json({
                message: "OTP expired. Please request a new one"
            });
        }

        // Check OTP
        if (user.resetOtp !== otp.toString().trim()) {
            return res.status(400).json({
                message: "Invalid OTP"
            });
        }

        // Hash and update password
        user.password = await bcrypt.hash(newPassword, 10);

        // Clear OTP after successful reset
        user.resetOtp = null;
        user.resetOtpExpiry = null;

        await user.save();

        return res.status(200).json({
            message: "Password reset successfully. Please login."
        });

    } catch (error) {
        console.error("Reset Password Error:", error);

        return res.status(500).json({
            message: "Unable to reset password"
        });
    }
};


// ==============================
// GET USER PROFILE
// ==============================
const getProfile = async (req, res) => {
    try {
        const user = await User.findById(req.user.id)
            .select("-password -resetOtp -resetOtpExpiry");

        if (!user) {
            return res.status(404).json({
                message: "User not found"
            });
        }

        return res.status(200).json({
            message: "Profile fetched successfully",
            user
        });

    } catch (error) {
        console.error("Profile Error:", error);

        return res.status(500).json({
            message: "Unable to fetch profile"
        });
    }
};


// ==============================
// EXPORT FUNCTIONS
// ==============================
module.exports = {
    registerUser,
    loginUser,
    forgotPassword,
    resetPassword,
    getProfile
};
