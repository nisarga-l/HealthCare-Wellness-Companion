
const Wellness = require("../models/Wellness");

// Add wellness record
const addWellness = async (req, res) => {
    try {
        const { category, value, unit, date, notes } = req.body;

        if (!category || value === undefined || !unit) {
            return res.status(400).json({
                message: "Category, value and unit are required"
            });
        }

        if (!["water", "sleep", "exercise", "weight"].includes(category)) {
            return res.status(400).json({
                message: "Invalid wellness category"
            });
        }

        const record = await Wellness.create({
            userId: req.user.id,
            category,
            value,
            unit,
            date,
            notes
        });

        res.status(201).json({
            message: "Wellness record added successfully",
            record
        });

    } catch (error) {
        res.status(500).json({
            message: error.message
        });
    }
};

// Get logged-in user's wellness records
const getWellness = async (req, res) => {
    try {
        const records = await Wellness.find({
            userId: req.user.id
        }).sort({ date: -1 });

        res.json(records);

    } catch (error) {
        res.status(500).json({
            message: error.message
        });
    }
};

// Update wellness record
const updateWellness = async (req, res) => {
    try {
        const { category, value, unit, date, notes } = req.body;

        const updates = {};

        if (category !== undefined) {
            if (!["water", "sleep", "exercise", "weight"].includes(category)) {
                return res.status(400).json({
                    message: "Invalid wellness category"
                });
            }
            updates.category = category;
        }

        if (value !== undefined) updates.value = value;
        if (unit !== undefined) updates.unit = unit;
        if (date !== undefined) updates.date = date;
        if (notes !== undefined) updates.notes = notes;

        const record = await Wellness.findOneAndUpdate(
            {
                _id: req.params.id,
                userId: req.user.id
            },
            { $set: updates },
            { new: true, runValidators: true }
        );

        if (!record) {
            return res.status(404).json({
                message: "Wellness record not found"
            });
        }

        res.json({
            message: "Wellness record updated successfully",
            record
        });

    } catch (error) {
        res.status(500).json({
            message: error.message
        });
    }
};

// Delete wellness record
const deleteWellness = async (req, res) => {
    try {
        const record = await Wellness.findOneAndDelete({
            _id: req.params.id,
            userId: req.user.id
        });

        if (!record) {
            return res.status(404).json({
                message: "Wellness record not found"
            });
        }

        res.json({
            message: "Wellness record deleted successfully"
        });

    } catch (error) {
        res.status(500).json({
            message: error.message
        });
    }
};

module.exports = {
    addWellness,
    getWellness,
    updateWellness,
    deleteWellness
};
