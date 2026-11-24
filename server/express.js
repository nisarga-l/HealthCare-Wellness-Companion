const express = require("express");
const cors = require("cors");

const authRoutes = require("./routes/authRoutes");
const wellnessRoutes = require("./routes/wellnessRoutes");
const medicationRoutes = require("./routes/medicationRoutes");

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Routes
app.use("/api/auth", authRoutes);
app.use("/api/wellness", wellnessRoutes);
app.use("/api/medications", medicationRoutes);

// Health check
app.get("/", (req, res) => {
    res.json({
        message: "HealthMate API is running!"
    });
});

// Error handler
app.use((err, req, res, next) => {
    console.error(err.stack);

    res.status(500).json({
        message: "Internal server error"
    });
});

module.exports = app;