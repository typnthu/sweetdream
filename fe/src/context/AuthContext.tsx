"use client";
import { createContext, useContext, useState, useEffect, ReactNode } from "react";

export type User = {
  id: number;
  name: string;
  email: string;
  phone?: string;
  address?: string;
  role?: 'customer' | 'admin';
};

type AuthContextType = {
  user: User | null;
  token: string | null;
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
  const [token, setToken] = useState<string | null>(null);
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [isLoading, setIsLoading] = useState(true);

  // Check for saved user on component mount
  useEffect(() => {
    const savedUser = localStorage.getItem('sweetdream_user');
    const savedToken = localStorage.getItem('sweetdream_token');
    if (savedUser && savedToken) {
      try {
        const userData = JSON.parse(savedUser);
        setUser(userData);
        setToken(savedToken);
        setIsAuthenticated(true);
      } catch (error) {
        console.error('Error parsing saved user data:', error);
        localStorage.removeItem('sweetdream_user');
        localStorage.removeItem('sweetdream_token');
      }
    }
    setIsLoading(false);
  }, []);

  const login = async (email: string, password: string): Promise<boolean> => {
    try {
      // Use user-service for authentication via proxy
      const response = await fetch('/api/proxy/auth/login', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ email, password }),
      });

      if (response.ok) {
        const data = await response.json();
        console.log('Login response data:', data); // Debug log
        console.log('User role:', data.user?.role); // Debug log
        setUser(data.user);
        setToken(data.token);
        setIsAuthenticated(true);
        
        // Save to localStorage
        localStorage.setItem('sweetdream_user', JSON.stringify(data.user));
        localStorage.setItem('sweetdream_token', data.token);
        
        // Also save to cookie for middleware
        document.cookie = `sweetdream_user=${JSON.stringify(data.user)}; path=/; max-age=604800`; // 7 days
        
        return true;
      }

      // Fallback to mock users if backend fails
      const foundUser = mockUsers.find(u => u.email === email && u.password === password);
      
      if (foundUser) {
        const { password: _, ...userWithoutPassword } = foundUser;
        
        // Try to create user in database via user-service
        try {
          const registerResponse = await fetch('/api/proxy/auth/register', {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
            },
            body: JSON.stringify({
              name: foundUser.name,
              email: foundUser.email,
              password: foundUser.password,
              phone: foundUser.phone,
              address: foundUser.address
            }),
          });

          if (registerResponse.ok) {
            const registerData = await registerResponse.json();
            setUser(registerData.user);
            setToken(registerData.token);
            setIsAuthenticated(true);
            
            localStorage.setItem('sweetdream_user', JSON.stringify(registerData.user));
            localStorage.setItem('sweetdream_token', registerData.token);
            document.cookie = `sweetdream_user=${JSON.stringify(registerData.user)}; path=/; max-age=604800`;
            
            return true;
          }
        } catch (e) {
          console.error('Failed to register mock user:', e);
        }
      }
      
      return false;
    } catch (error) {
      console.error('Login error:', error);
      return false;
    }
  };

  const register = async (userData: Omit<User, 'id'> & { password: string }): Promise<boolean> => {
    try {
      // Use user-service for registration via proxy
      const response = await fetch('/api/proxy/auth/register', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(userData),
      });

      if (response.ok) {
        const data = await response.json();
        setUser(data.user);
        setToken(data.token);
        setIsAuthenticated(true);
        
        // Save to localStorage
        localStorage.setItem('sweetdream_user', JSON.stringify(data.user));
        localStorage.setItem('sweetdream_token', data.token);
        
        // Also save to cookie for middleware
        document.cookie = `sweetdream_user=${JSON.stringify(data.user)}; path=/; max-age=604800`; // 7 days
        
        return true;
      }

      return false;
    } catch (error) {
      console.error('Registration error:', error);
      return false;
    }
  };

  const logout = () => {
    setUser(null);
    setToken(null);
    setIsAuthenticated(false);
    localStorage.removeItem('sweetdream_user');
    localStorage.removeItem('sweetdream_token');
    
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
      token,
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