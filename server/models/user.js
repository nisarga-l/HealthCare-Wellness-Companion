
const mongoose = require("mongoose");

const userSchema = new mongoose.Schema(
    {
        name: {
            type: String,
            required: true,
            trim: true
        },

        email: {
            type: String,
            required: true,
            unique: true,
            lowercase: true,
            trim: true
        },

        password: {
            type: String,
            required: true
        },

        age: {
            type: Number,
            min: 13,
            max: 120
        },

        gender: {
            type: String,
            default: ""
        },

        height: {
            type: Number,
            min: 50,
            max: 250
        },

        weight: {
            type: Number,
            min: 1,
            max: 500
        },

        targetWeight: {
            type: Number,
            min: 1,
            max: 500
        },

        goal: {
            type: String,
            enum: ["lose", "gain", "maintain", ""],
            default: ""
        },

        // Password reset fields (exhibition demo)
        resetOtp: {
            type: String,
            default: null
        },

        resetOtpExpiry: {
            type: Date,
            default: null
        }
    },
    {
        timestamps: true
    }
);

module.exports = mongoose.model("User", userSchema);
