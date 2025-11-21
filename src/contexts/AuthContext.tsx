'use client';

import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';

interface AuthContextType {
  isAuthenticated: boolean;
  userName: string | null;
  userEmail: string | null;
  login: (token: string, name: string, email: string) => void;
  logout: () => void;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [userName, setUserName] = useState<string | null>(null);
  const [userEmail, setUserEmail] = useState<string | null>(null);

  // Check localStorage on mount
  useEffect(() => {
    const token = localStorage.getItem('authToken');
    const name = localStorage.getItem('userName');
    const email = localStorage.getItem('userEmail');

    if (token) {
      setIsAuthenticated(true);
      setUserName(name);
      setUserEmail(email);
    }
  }, []);

  const login = (token: string, name: string, email: string) => {
    localStorage.setItem('authToken', token);
    localStorage.setItem('userName', name);
    localStorage.setItem('userEmail', email);
    
    setIsAuthenticated(true);
    setUserName(name);
    setUserEmail(email);
  };

  const logout = () => {
    localStorage.removeItem('authToken');
    localStorage.removeItem('userName');
    localStorage.removeItem('userEmail');
    
    setIsAuthenticated(false);
    setUserName(null);
    setUserEmail(null);
  };

  return (
    <AuthContext.Provider value={{ isAuthenticated, userName, userEmail, login, logout }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};
