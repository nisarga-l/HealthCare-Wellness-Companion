
const mongoose = require("mongoose");

const wellnessSchema = new mongoose.Schema(
    {
        userId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "User",
            required: true
        },

        category: {
            type: String,
            enum: ["water", "sleep", "exercise", "weight"],
            required: true
        },

        value: {
            type: Number,
            required: true,
            min: 0
        },

        unit: {
            type: String,
            required: true
        },

        date: {
            type: Date,
            default: Date.now
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

module.exports = mongoose.model("Wellness", wellnessSchema);
