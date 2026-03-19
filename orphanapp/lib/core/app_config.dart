class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://fvsfpphlepguohflnnhs.supabase.co');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ2c2ZwcGhsZXBndW9oZmxubmhzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM2MDExMDgsImV4cCI6MjA4OTE3NzEwOH0.YI036PrEzH8JId-8_L3x-56YX1j7mY9i0cT5OWjGanA');

  static bool get isConfigured =>
      supabaseUrl.trim().isNotEmpty && supabaseAnonKey.trim().isNotEmpty;
}
