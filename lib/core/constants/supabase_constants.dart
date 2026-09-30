// TODO: Ganti nilai ini dengan Supabase project Anda
// Dapatkan dari: https://supabase.com/dashboard → Project Settings → API
class SupabaseConstants {
  SupabaseConstants._();

  static const String url = 'https://eqbhslskhzlrsosmrqjo.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVxYmhzbHNraHpscnNvc21ycWpvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTA2MDU3NzQsImV4cCI6MjEwNjE4MTc3NH0.V2zTiQDdehS9g6vNvodaxzN2Q-CzAYXwU4wzatFi5Ts';

  // REST endpoints
  static const String authEndpoint = '$url/auth/v1';
  static const String restEndpoint = '$url/rest/v1';
}
