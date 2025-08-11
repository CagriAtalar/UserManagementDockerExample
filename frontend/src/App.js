import React, { useState, useEffect } from 'react';
import axios from 'axios';
import './App.css';

function App() {
    const [users, setUsers] = useState([]);
    const [formData, setFormData] = useState({
        name: '',
        phone: '',
        email: ''
    });
    const [editingId, setEditingId] = useState(null);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');

    const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:5000';

    useEffect(() => {
        fetchUsers();
    }, []);

    const fetchUsers = async () => {
        try {
            setLoading(true);
            const response = await axios.get(`${API_BASE_URL}/api/users`);
            setUsers(response.data);
            setError('');
        } catch (err) {
            setError('Failed to fetch users');
            console.error('Error fetching users:', err);
        } finally {
            setLoading(false);
        }
    };

    const handleInputChange = (e) => {
        const { name, value } = e.target;
        setFormData(prev => ({
            ...prev,
            [name]: value
        }));
    };

    const handleSubmit = async (e) => {
        e.preventDefault();

        if (!formData.name || !formData.phone || !formData.email) {
            setError('All fields are required');
            return;
        }

        try {
            setLoading(true);
            if (editingId) {
                // Update existing user
                await axios.put(`${API_BASE_URL}/api/users/${editingId}`, formData);
                setEditingId(null);
            } else {
                // Create new user
                await axios.post(`${API_BASE_URL}/api/users`, formData);
            }

            setFormData({ name: '', phone: '', email: '' });
            fetchUsers();
            setError('');
        } catch (err) {
            setError(err.response?.data?.error || 'Failed to save user');
            console.error('Error saving user:', err);
        } finally {
            setLoading(false);
        }
    };

    const handleEdit = (user) => {
        setFormData({
            name: user.name,
            phone: user.phone,
            email: user.email
        });
        setEditingId(user.id);
    };

    const handleDelete = async (id) => {
        if (window.confirm('Are you sure you want to delete this user?')) {
            try {
                setLoading(true);
                await axios.delete(`${API_BASE_URL}/api/users/${id}`);
                fetchUsers();
                setError('');
            } catch (err) {
                setError('Failed to delete user');
                console.error('Error deleting user:', err);
            } finally {
                setLoading(false);
            }
        }
    };

    const handleCancel = () => {
        setEditingId(null);
        setFormData({ name: '', phone: '', email: '' });
        setError('');
    };

    return (
        <div className="App">
            <header className="App-header">
                <h1>User Management System</h1>
            </header>

            <main className="App-main">
                <div className="form-container">
                    <h2>{editingId ? 'Edit User' : 'Add New User'}</h2>

                    {error && <div className="error-message">{error}</div>}

                    <form onSubmit={handleSubmit} className="user-form">
                        <div className="form-group">
                            <label htmlFor="name">Name:</label>
                            <input
                                type="text"
                                id="name"
                                name="name"
                                value={formData.name}
                                onChange={handleInputChange}
                                placeholder="Enter name"
                                required
                            />
                        </div>

                        <div className="form-group">
                            <label htmlFor="phone">Phone:</label>
                            <input
                                type="tel"
                                id="phone"
                                name="phone"
                                value={formData.phone}
                                onChange={handleInputChange}
                                placeholder="Enter phone number"
                                required
                            />
                        </div>

                        <div className="form-group">
                            <label htmlFor="email">Email:</label>
                            <input
                                type="email"
                                id="email"
                                name="email"
                                value={formData.email}
                                onChange={handleInputChange}
                                placeholder="Enter email"
                                required
                            />
                        </div>

                        <div className="form-buttons">
                            <button type="submit" disabled={loading}>
                                {loading ? 'Saving...' : (editingId ? 'Update' : 'Add')}
                            </button>
                            {editingId && (
                                <button type="button" onClick={handleCancel} className="cancel-btn">
                                    Cancel
                                </button>
                            )}
                        </div>
                    </form>
                </div>

                <div className="users-container">
                    <h2>Users List</h2>

                    {loading && users.length === 0 ? (
                        <div className="loading">Loading users...</div>
                    ) : users.length === 0 ? (
                        <div className="no-users">No users found. Add your first user above!</div>
                    ) : (
                        <div className="users-table">
                            <table>
                                <thead>
                                    <tr>
                                        <th>ID</th>
                                        <th>Name</th>
                                        <th>Phone</th>
                                        <th>Email</th>
                                        <th>Actions</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {users.map(user => (
                                        <tr key={user.id}>
                                            <td>{user.id}</td>
                                            <td>{user.name}</td>
                                            <td>{user.phone}</td>
                                            <td>{user.email}</td>
                                            <td>
                                                <button
                                                    onClick={() => handleEdit(user)}
                                                    className="edit-btn"
                                                    disabled={loading}
                                                >
                                                    Edit
                                                </button>
                                                <button
                                                    onClick={() => handleDelete(user.id)}
                                                    className="delete-btn"
                                                    disabled={loading}
                                                >
                                                    Delete
                                                </button>
                                            </td>
                                        </tr>
                                    ))}
                                </tbody>
                            </table>
                        </div>
                    )}
                </div>
            </main>
        </div>
    );
}

export default App;
