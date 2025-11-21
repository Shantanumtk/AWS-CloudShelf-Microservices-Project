'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { Header } from '@/components/Header';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { useAuth } from '@/contexts/AuthContext';
import { Loader, Mail, Lock, Eye, EyeOff } from 'lucide-react';

export default function LoginPage() {
  const router = useRouter();
  const { login } = useAuth(); // Use AuthContext
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!email || !password) {
      setError('Please enter both email and password');
      return;
    }

    try {
      setLoading(true);
      setError(null);

      // Simulate API call (replace with real API later)
      await new Promise(resolve => setTimeout(resolve, 500));
      
      // Call login from AuthContext
      login('demo-token-12345', 'Demo User', email);

      // Redirect to home page
      router.push('/');
    } catch (err: any) {
      setError('Invalid email or password');
      console.error('Login failed:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleDemoLogin = () => {
    // Call login from AuthContext
    login('demo-token-12345', 'Demo User', 'demo@bookverse.com');
    
    // Redirect to home page
    router.push('/');
  };

  return (
    <div className="min-h-screen bg-background">
      <Header
        cartCount={0}
        wishlistCount={0}
        onSearch={(q) => router.push(`/search?q=${q}`)}
        isAuthenticated={false}
        userName={undefined}
      />

      <main className="container mx-auto px-4 py-12">
        <div className="max-w-md mx-auto">
          {/* Header */}
          <div className="text-center mb-8">
            <h1 className="text-4xl font-bold mb-2">Welcome Back</h1>
            <p className="text-muted-foreground">
              Sign in to your BookVerse account
            </p>
          </div>

          {/* Login Card */}
          <Card>
            <CardHeader>
              <CardTitle>Sign In</CardTitle>
            </CardHeader>
            <CardContent>
              <form onSubmit={handleLogin} className="space-y-4">
                {/* Error Message */}
                {error && (
                  <div className="bg-destructive/10 text-destructive p-3 rounded-lg text-sm">
                    {error}
                  </div>
                )}

                {/* Email Field */}
                <div>
                  <label className="block text-sm font-semibold mb-2">
                    Email Address
                  </label>
                  <div className="relative">
                    <Mail className="absolute left-3 top-1/2 -translate-y-1/2 text-muted-foreground" size={18} />
                    <Input
                      type="email"
                      placeholder="you@example.com"
                      value={email}
                      onChange={(e) => setEmail(e.target.value)}
                      className="pl-10"
                      disabled={loading}
                    />
                  </div>
                </div>

                {/* Password Field */}
                <div>
                  <label className="block text-sm font-semibold mb-2">
                    Password
                  </label>
                  <div className="relative">
                    <Lock className="absolute left-3 top-1/2 -translate-y-1/2 text-muted-foreground" size={18} />
                    <Input
                      type={showPassword ? 'text' : 'password'}
                      placeholder="Enter your password"
                      value={password}
                      onChange={(e) => setPassword(e.target.value)}
                      className="pl-10 pr-10"
                      disabled={loading}
                    />
                    <button
                      type="button"
                      onClick={() => setShowPassword(!showPassword)}
                      className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground"
                    >
                      {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
                    </button>
                  </div>
                </div>

                {/* Remember Me & Forgot Password */}
                <div className="flex items-center justify-between">
                  <label className="flex items-center gap-2 cursor-pointer">
                    <input type="checkbox" className="w-4 h-4" />
                    <span className="text-sm">Remember me</span>
                  </label>
                  <Link
                    href="/forgot-password"
                    className="text-sm text-primary hover:underline"
                  >
                    Forgot password?
                  </Link>
                </div>

                {/* Submit Button */}
                <Button
                  type="submit"
                  className="w-full"
                  size="lg"
                  disabled={loading}
                >
                  {loading ? (
                    <>
                      <Loader className="animate-spin mr-2" size={20} />
                      Signing In...
                    </>
                  ) : (
                    'Sign In'
                  )}
                </Button>
              </form>

              {/* Divider */}
              <div className="relative my-6">
                <div className="absolute inset-0 flex items-center">
                  <div className="w-full border-t"></div>
                </div>
                <div className="relative flex justify-center text-sm">
                  <span className="bg-background px-2 text-muted-foreground">
                    or
                  </span>
                </div>
              </div>

              {/* Demo Login */}
              <Button
                type="button"
                variant="outline"
                className="w-full mb-4"
                onClick={handleDemoLogin}
              >
                Demo Login
              </Button>

              {/* Sign Up Link */}
              <div className="text-center mt-6">
                <p className="text-sm text-muted-foreground">
                  Don't have an account?{' '}
                  <Link
                    href="/signup"
                    className="text-primary font-semibold hover:underline"
                  >
                    Create Account
                  </Link>
                </p>
              </div>
            </CardContent>
          </Card>

          {/* Additional Info */}
          <Card className="mt-6 bg-muted/30">
            <CardContent className="p-6">
              <h3 className="font-semibold mb-2">Why Sign In?</h3>
              <ul className="text-sm text-muted-foreground space-y-1">
                <li>• Save books to your wishlist</li>
                <li>• Track your orders and shipments</li>
                <li>• Get personalized recommendations</li>
                <li>• Faster checkout with saved addresses</li>
                <li>• View your reading history</li>
              </ul>
            </CardContent>
          </Card>
        </div>
      </main>
    </div>
  );
}
