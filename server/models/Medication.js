const mongoose = require("mongoose");

const medicationSchema = new mongoose.Schema(
    {
        userId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "User",
            required: true
        },

        medicationName: {
            type: String,
            required: true,
            trim: true
        },

        dosage: {
            type: String,
            required: true
        },

        instructions: {
            type: String,
            default: ""
        },

        frequency: {
            type: String,
            enum: [
                "Daily",
                "Twice daily",
                "Three times daily",
                "Weekly",
                "As needed",
                "Custom"
            ],
            default: "Daily"
        },

        reminderTimes: {
            type: [String],
            default: []
        },

        startDate: {
            type: Date,
            required: true
        },

        endDate: {
            type: Date,
            default: null
        },

        isActive: {
            type: Boolean,
            default: true
        },

        notes: {
            type: String,
            default: ""
        }
    },
    {
        timestamps: true
    }
);

module.exports = mongoose.model("Medication", medicationSchema);