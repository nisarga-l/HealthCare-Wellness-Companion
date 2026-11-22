
const express = require("express");

const {
    addWellness,
    getWellness,
    updateWellness,
    deleteWellness
} = require("../controllers/wellnessController");

const authMiddleware = require("../middleware/authMiddleware");

const router = express.Router();

// Add wellness record
router.post("/", authMiddleware, addWellness);

// Get all wellness records
router.get("/", authMiddleware, getWellness);

// Update wellness record
router.put("/:id", authMiddleware, updateWellness);

// Delete wellness record
router.delete("/:id", authMiddleware, deleteWellness);

module.exports = router;
