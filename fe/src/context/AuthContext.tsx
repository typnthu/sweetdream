"use client";
import { createContext, useContext, useState, useEffect, ReactNode } from "react";

export type User = {
  id: number;
  name: string;
  email: string;
  phone?: string;
  address?: string;
  role?: 'customer' | 'admin'; // Add role field
};

type AuthContextType = {
  user: User | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  login: (email: string, password: string) => Promise<boolean>;
  register: (userData: Omit<User, 'id'> & { password: string }) => Promise<boolean>;
  logout: () => void;
  updateProfile: (userData: Partial<User>) => void;
};

const AuthContext = createContext<AuthContextType | undefined>(undefined);

// Mock users for demonstration - replace with actual API
const mockUsers: (User & { password: string })[] = [
  {
    id: 1,
    name: "Nguyễn Văn A",
    email: "user@example.com",
    phone: "0123456789",
    address: "123 Đường ABC, Quận 1, TP.HCM",
    password: "123456",
    role: "customer"
  },
  {
    id: 2,
    name: "Admin",
    email: "admin@sweetdream.com",
    phone: "0987654321",
    address: "Cửa hàng SweetDream",
    password: "admin123",
    role: "admin"
  }
];

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [isLoading, setIsLoading] = useState(true);

  // Check for saved user on component mount
  useEffect(() => {
    const savedUser = localStorage.getItem('sweetdream_user');
    if (savedUser) {
      try {
        const userData = JSON.parse(savedUser);
        setUser(userData);
        setIsAuthenticated(true);
      } catch (error) {
        console.error('Error parsing saved user data:', error);
        localStorage.removeItem('sweetdream_user');
      }
    }
    setIsLoading(false);
  }, []);

  const login = async (email: string, password: string): Promise<boolean> => {
    try {
      // Simple login - check hardcoded users
      const foundUser = mockUsers.find(u => u.email === email && u.password === password);
      
      if (foundUser) {
        const { password: _, ...userWithoutPassword } = foundUser;
        setUser(userWithoutPassword);
        setIsAuthenticated(true);
        
        // Save to localStorage
        localStorage.setItem('sweetdream_user', JSON.stringify(userWithoutPassword));
        
        // Also save to cookie for middleware
        document.cookie = `sweetdream_user=${JSON.stringify(userWithoutPassword)}; path=/; max-age=604800`; // 7 days
        
        return true;
      }
      
      return false;
    } catch (error) {
      console.error('Login error:', error);
      return false;
    }
  };

  const register = async (userData: Omit<User, 'id'> & { password: string }): Promise<boolean> => {
    try {
      // Check if user already exists in mock users
      const existingMockUser = mockUsers.find(u => u.email === userData.email);
      if (existingMockUser) {
        return false; // User already exists
      }

      // Create customer in database via API
      const { password, ...customerData } = userData;
      
      const response = await fetch('/api/proxy/customers', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(customerData),
      });

      if (!response.ok) {
        const error = await response.json();
        console.error('Failed to create customer:', error);
        return false; // Email already exists in database or other error
      }

      const createdCustomer = await response.json();

      // Add to mock users for authentication
      const newUser = {
        ...userData,
        id: createdCustomer.id, // Use the ID from database
      };

      mockUsers.push(newUser);
      
      const { password: _, ...userWithoutPassword } = newUser;
      setUser(userWithoutPassword);
      setIsAuthenticated(true);
      
      // Save to localStorage
      localStorage.setItem('sweetdream_user', JSON.stringify(userWithoutPassword));
      
      // Also save to cookie for middleware
      document.cookie = `sweetdream_user=${JSON.stringify(userWithoutPassword)}; path=/; max-age=604800`; // 7 days
      
      return true;
    } catch (error) {
      console.error('Registration error:', error);
      return false;
    }
  };

  const logout = () => {
    setUser(null);
    setIsAuthenticated(false);
    localStorage.removeItem('sweetdream_user');
    
    // Clear cookie
    document.cookie = 'sweetdream_user=; path=/; max-age=0';
  };

  const updateProfile = (userData: Partial<User>) => {
    if (user) {
      const updatedUser = { ...user, ...userData };
      setUser(updatedUser);
      localStorage.setItem('sweetdream_user', JSON.stringify(updatedUser));
      
      // Update in mock users array
      const userIndex = mockUsers.findIndex(u => u.id === user.id);
      if (userIndex !== -1) {
        mockUsers[userIndex] = { ...mockUsers[userIndex], ...userData };
      }
    }
  };

  return (
    <AuthContext.Provider value={{
      user,
      isAuthenticated,
      isLoading,
      login,
      register,
      logout,
      updateProfile
    }}>
      {children}
    </AuthContext.Provider>
  );
}

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error("useAuth must be used within AuthProvider");
  }
  return context;
};