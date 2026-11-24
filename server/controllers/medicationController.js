const Medication = require("../models/Medication");

// Get all medications for logged-in user
const getMedications = async (req, res) => {
    try {
        const userId = req.user.id;

        const medications = await Medication.find({ userId })
            .sort({ createdAt: -1 });

        res.status(200).json({
            success: true,
            count: medications.length,
            medications
        });

    } catch (error) {
        console.error("Get medications error:", error);

        res.status(500).json({
            success: false,
            message: "Failed to fetch medications"
        });
    }
};


// Add new medication
const addMedication = async (req, res) => {
    try {
        const userId = req.user.id;

        const {
            medicationName,
            dosage,
            instructions,
            frequency,
            reminderTimes,
            startDate,
            endDate,
            notes
        } = req.body;

        if (!medicationName || !dosage || !startDate) {
            return res.status(400).json({
                success: false,
                message: "Medication name, dosage and start date are required"
            });
        }

        const medication = await Medication.create({
            userId,
            medicationName,
            dosage,
            instructions,
            frequency,
            reminderTimes,
            startDate,
            endDate,
            notes
        });

        res.status(201).json({
            success: true,
            message: "Medication added successfully",
            medication
        });

    } catch (error) {
        console.error("Add medication error:", error);

        res.status(500).json({
            success: false,
            message: "Failed to add medication"
        });
    }
};


// Update medication
const updateMedication = async (req, res) => {
    try {
        const userId = req.user.id;
        const medicationId = req.params.id;

        const medication = await Medication.findOneAndUpdate(
            {
                _id: medicationId,
                userId
            },
            req.body,
            {
                new: true,
                runValidators: true
            }
        );

        if (!medication) {
            return res.status(404).json({
                success: false,
                message: "Medication not found"
            });
        }

        res.status(200).json({
            success: true,
            message: "Medication updated successfully",
            medication
        });

    } catch (error) {
        console.error("Update medication error:", error);

        res.status(500).json({
            success: false,
            message: "Failed to update medication"
        });
    }
};


// Delete medication
const deleteMedication = async (req, res) => {
    try {
        const userId = req.user.id;
        const medicationId = req.params.id;

        const medication = await Medication.findOneAndDelete({
            _id: medicationId,
            userId
        });

        if (!medication) {
            return res.status(404).json({
                success: false,
                message: "Medication not found"
            });
        }

        res.status(200).json({
            success: true,
            message: "Medication deleted successfully"
        });

    } catch (error) {
        console.error("Delete medication error:", error);

        res.status(500).json({
            success: false,
            message: "Failed to delete medication"
        });
    }
};


module.exports = {
    getMedications,
    addMedication,
    updateMedication,
    deleteMedication
};