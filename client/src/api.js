import axios from "axios";

const API = axios.create({
    baseURL: "https://healthcare-wellness-companion-1.onrender.com/api",
    headers: {
        "Content-Type": "application/json"
    }
});

// Automatically attach JWT token to every API request
API.interceptors.request.use(
    (config) => {
        const token = localStorage.getItem("token");

        if (token) {
            config.headers.Authorization = `Bearer ${token}`;
        }

        return config;
    },
    (error) => {
        return Promise.reject(error);
    }
);

export default API;