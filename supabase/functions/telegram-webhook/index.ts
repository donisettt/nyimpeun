import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const TELEGRAM_BOT_TOKEN = Deno.env.get('TELEGRAM_BOT') || Deno.env.get('TELEGRAM_BOT_TOKEN') || '';
const GROQ_API_KEY = Deno.env.get('GROQ_API_KEY') || '';
const GEMINI_API_KEY = Deno.env.get('GEMINI_API_KEY') || '';
const OPENAI_API_KEY = Deno.env.get('OPENAI_API_KEY') || '';
const SUPABASE_URL = Deno.env.get('SUPABASE_URL') || '';
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || '';

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

async function sendTelegramMessage(chatId: number, text: string) {
  const url = `https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage`;
  await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ chat_id: chatId, text }),
  });
}

async function handleOTP(chatId: number, text: string) {
  let code = text.trim();
  if (text.startsWith('/start ')) {
    code = text.split(' ')[1];
  }
  if (!code) {
    await sendTelegramMessage(chatId, "Format salah. Gunakan link dari aplikasi Nyimpeun.");
    return;
  }

  // Find pending binding
  const { data, error } = await supabase
    .from('telegram_bindings')
    .select('*')
    .eq('otp_code', code)
    .eq('status', 'PENDING')
    .single();

  if (error || !data) {
    await sendTelegramMessage(chatId, "Kode OTP tidak valid atau sudah kadaluarsa.");
    return;
  }

  // Check expiration
  if (new Date(data.expires_at) < new Date()) {
    await sendTelegramMessage(chatId, "Kode OTP sudah kadaluarsa. Silakan generate ulang di aplikasi.");
    return;
  }

  // Delete old bindings for this chat id
  await supabase
    .from('telegram_bindings')
    .delete()
    .eq('telegram_chat_id', chatId);

  // Update binding
  const { error: updateError } = await supabase
    .from('telegram_bindings')
    .update({ telegram_chat_id: chatId, status: 'LINKED' })
    .eq('id', data.id);

  if (updateError) {
    await sendTelegramMessage(chatId, "Gagal menautkan akun. Coba lagi nanti.");
    return;
  }

  await sendTelegramMessage(chatId, "Akun Nyimpeun berhasil dihubungkan! 🎉\n\nSekarang kamu bisa mencatat pengeluaran langsung di sini. Contoh:\n'makan siang 50rb pake bca'");
}

async function processTransaction(chatId: number, text: string) {
  try {
    // 1. Get user id from chat id
    const { data: bindings, error: bindingError } = await supabase
      .from('telegram_bindings')
      .select('user_id')
      .eq('telegram_chat_id', chatId)
      .eq('status', 'LINKED')
      .order('created_at', { ascending: false })
      .limit(1);

    const binding = bindings?.[0];

    if (bindingError || !binding) {
      await sendTelegramMessage(chatId, "Akun belum terhubung. Silakan hubungkan dari aplikasi Nyimpeun.");
      return;
    }

    const userId = binding.user_id;

    // 2. Fetch User's Wallets and Categories for Context
    const [{ data: wallets }, { data: categories }] = await Promise.all([
      supabase.from('wallets').select('id, name, type').eq('user_id', userId),
      supabase.from('categories').select('id, name, type').or(`user_id.eq.${userId},is_default.eq.true`),
    ]);

    const walletContext = wallets?.map((w) => `${w.name} (id: ${w.id})`).join(', ') || '';
    const categoryContext = categories?.map((c) => `${c.name} (id: ${c.id})`).join(', ') || '';

    // 3. System Prompt
    const systemPrompt = `Kamu adalah asisten pencatat keuangan. Ekstrak pesan user menjadi JSON.
Wajib gunakan schema berikut:
{
  "type": "EXPENSE" | "INCOME",
  "amount": number,
  "wallet_id": string (uuid dari daftar dompet di bawah),
  "category_id": string (uuid dari daftar kategori di bawah),
  "note": string (singkat)
}
Daftar Dompet User: [${walletContext}]
Daftar Kategori User: [${categoryContext}]

Panduan penting:
1. Jika pesan bermakna uang masuk (contoh: "gaji", "dapat", "terima", "bonus", "dikasih", "jual"), maka "type": "INCOME".
2. Jika pesan bermakna uang keluar (contoh: "beli", "bayar", "jajan", "makan", "ongkos"), maka "type": "EXPENSE".
3. Cocokkan kategori dengan cermat berdasarkan "type" tersebut.
4. Hanya balas dengan JSON murni tanpa markdown (\`\`\`json), tanpa awalan atau penjelasan apapun.`;

    // 4. LLM Fallback (Groq -> Gemini -> OpenAI)
    let llmResult = '';
    
    // Attempt 1: Groq (Llama-3)
    try {
      if (!GROQ_API_KEY) throw new Error("GROQ_API_KEY missing");
      const groqRes = await fetch('https://api.groq.com/openai/v1/chat/completions', {
        method: 'POST',
        headers: { 'Authorization': `Bearer ${GROQ_API_KEY}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({
          model: 'openai/gpt-oss-120b',
          messages: [{ role: 'system', content: systemPrompt }, { role: 'user', content: text }],
          temperature: 0.1
        })
      });
      if (!groqRes.ok) throw new Error(`Groq failed: ${groqRes.status}`);
      const data = await groqRes.json();
      llmResult = data.choices[0].message.content;
    } catch (e) {
      console.error("Groq fallback triggered:", e);
      // Attempt 2: Gemini
      try {
        if (!GEMINI_API_KEY) throw new Error("GEMINI_API_KEY missing");
        const geminiRes = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${GEMINI_API_KEY}`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            system_instruction: { parts: { text: systemPrompt } },
            contents: [{ parts: [{ text }] }],
            generationConfig: { temperature: 0.1 }
          })
        });
        if (!geminiRes.ok) throw new Error(`Gemini failed: ${geminiRes.status}`);
        const data = await geminiRes.json();
        llmResult = data.candidates[0].content.parts[0].text;
      } catch (e2) {
        console.error("Gemini fallback triggered:", e2);
        // Attempt 3: OpenAI (GPT-4o-mini)
        if (!OPENAI_API_KEY) throw new Error("OPENAI_API_KEY missing");
        const oaiRes = await fetch('https://api.openai.com/v1/chat/completions', {
          method: 'POST',
          headers: { 'Authorization': `Bearer ${OPENAI_API_KEY}`, 'Content-Type': 'application/json' },
          body: JSON.stringify({
            model: 'gpt-4o-mini',
            messages: [{ role: 'system', content: systemPrompt }, { role: 'user', content: text }],
            temperature: 0.1
          })
        });
        if (!oaiRes.ok) throw new Error(`OpenAI failed: ${oaiRes.status}`);
        const data = await oaiRes.json();
        llmResult = data.choices[0].message.content;
      }
    }

    // 5. Parse JSON
    const cleanJson = llmResult.replace(/```json/g, '').replace(/```/g, '').trim();
    const parsed = JSON.parse(cleanJson);

    const parsedWalletId = parsed.wallet_id?.trim() ? parsed.wallet_id.trim() : null;
    const parsedCategoryId = parsed.category_id?.trim() ? parsed.category_id.trim() : null;

    // 6. Insert to Supabase
    const { error: insertError } = await supabase.from('transactions').insert({
      user_id: userId,
      type: (parsed.type || 'expense').toLowerCase(),
      amount: parsed.amount,
      wallet_id: parsedWalletId,
      category_id: parsedCategoryId,
      note: parsed.note,
      date: new Date().toISOString()
    });

    if (insertError) {
      console.error(insertError);
      await sendTelegramMessage(chatId, `Gagal menyimpan ke database. Error: ${insertError.message}`);
      return;
    }

    // Optional: Get names for confirmation
    const catName = categories?.find(c => c.id === parsed.category_id)?.name || 'Kategori';
    const walName = wallets?.find(w => w.id === parsed.wallet_id)?.name || 'Dompet';
    const amountFmt = new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR' }).format(parsed.amount);
    const isIncome = (parsed.type || 'expense').toLowerCase() === 'income';
    const typeLabel = isIncome ? 'Pemasukan' : 'Pengeluaran';
    const emoji = isIncome ? '💵' : '💸';

    const replyMessage = `✅ Berhasil mencatat ${typeLabel}!\n\n${emoji} Nominal: ${amountFmt}\n📁 Kategori: ${catName}\n💳 Dompet: ${walName}\n📝 Catatan: ${parsed.note || '-'}`;
    await sendTelegramMessage(chatId, replyMessage);

    // --- Send Push Notification via FCM ---
    try {
      const { data: tokenData, error: tokenError } = await supabase
        .from('user_fcm_tokens')
        .select('fcm_token')
        .eq('user_id', userId);

      console.log(`[FCM] userId: ${userId}, tokenCount: ${tokenData?.length ?? 0}, tokenError: ${tokenError?.message ?? 'none'}`);

      if (tokenData && tokenData.length > 0) {
        const serviceAccountStr = Deno.env.get('FIREBASE_SERVICE_ACCOUNT');
        if (!serviceAccountStr) {
          console.log("[FCM] FIREBASE_SERVICE_ACCOUNT is not set. Skipping.");
        } else {
          const serviceAccount = JSON.parse(serviceAccountStr);
          console.log(`[FCM] Using project: ${serviceAccount.project_id}`);

          // Generate OAuth2 token manually for FCM v1
          const { SignJWT } = await import('https://deno.land/x/jose@v4.14.4/jwt/sign.ts');
          const { importPKCS8 } = await import('https://deno.land/x/jose@v4.14.4/key/import.ts');
          
          const privateKeyStr = serviceAccount.private_key.replace(/\\n/g, '\n');
          const privateKey = await importPKCS8(privateKeyStr, 'RS256');
          const jwt = await new SignJWT({
            iss: serviceAccount.client_email,
            sub: serviceAccount.client_email,
            aud: 'https://oauth2.googleapis.com/token',
            scope: 'https://www.googleapis.com/auth/firebase.messaging',
          })
            .setProtectedHeader({ alg: 'RS256', typ: 'JWT' })
            .setIssuedAt()
            .setExpirationTime('1h')
            .sign(privateKey);

          const tokenRes = await fetch('https://oauth2.googleapis.com/token', {
            method: 'POST',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
            body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`
          });
          const tokenJson = await tokenRes.json();
          const accessToken = tokenJson.access_token;
          console.log(`[FCM] Got access token: ${accessToken ? 'YES' : 'NO'}, error: ${tokenJson.error ?? 'none'}`);

          for (const { fcm_token } of tokenData) {
            const fcmRes = await fetch(`https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`, {
              method: 'POST',
              headers: {
                'Authorization': `Bearer ${accessToken}`,
                'Content-Type': 'application/json',
              },
              body: JSON.stringify({
                message: {
                  token: fcm_token,
                  notification: {
                    title: isIncome ? '💵 Pemasukan Baru' : '💸 Pengeluaran Baru',
                    body: `${amountFmt} • ${catName} • ${walName}`,
                  },
                  android: {
                    priority: 'HIGH',
                    notification: {
                      sound: 'default',
                      channel_id: 'nyimpeun_transactions',
                    }
                  },
                  data: {
                    type: 'transaction',
                    transaction_type: parsed.type.toLowerCase(),
                    wallet_id: parsedWalletId || '',
                  }
                }
              }),
            });
            const fcmJson = await fcmRes.json();
            console.log(`[FCM] Send result: ${JSON.stringify(fcmJson)}`);
            if (!fcmRes.ok) {
              await sendTelegramMessage(chatId, `[DEBUG FCM RESPONSE ERROR]: ${JSON.stringify(fcmJson)}`);
            }
          }
        }
      } else {
        console.log("[FCM] No FCM tokens found for user. Notification skipped.");
      }
    } catch (pushErr) {
      console.error("[FCM] Failed to send push notification:", pushErr);
      await sendTelegramMessage(chatId, `[DEBUG FCM ERROR]: ${pushErr.message || pushErr}`);
    }

  } catch (e) {
    console.error(e);
    await sendTelegramMessage(chatId, "Maaf, sistem AI sedang kesulitan memahami pesannya. Pastikan sebutkan nama dompet & kategorinya.");
  }
}

serve(async (req) => {
  // Webhook Security Validation (Optional but Recommended)
  // const secret = req.headers.get('x-telegram-bot-api-secret-token');
  // if (secret !== Deno.env.get('TELEGRAM_SECRET_TOKEN')) return new Response("Unauthorized", { status: 401 });

  try {
    const body = await req.json();
    const message = body.message;

    if (!message || !message.text) {
      return new Response("OK", { status: 200 }); // Ignore non-text
    }

    const chatId = message.chat.id;
    const text = message.text.trim();

    // Async execution to avoid Telegram timeout
    if (text.startsWith('/start ') || text.startsWith('NYMP-')) {
      if (typeof EdgeRuntime !== 'undefined') {
        EdgeRuntime.waitUntil(handleOTP(chatId, text));
      } else {
        handleOTP(chatId, text); 
      }
    } else if (!text.startsWith('/')) {
      if (typeof EdgeRuntime !== 'undefined') {
        EdgeRuntime.waitUntil(processTransaction(chatId, text));
      } else {
        processTransaction(chatId, text);
      }
    }

    // Return 200 OK immediately
    return new Response("OK", { status: 200 });
  } catch (error) {
    console.error(error);
    return new Response("Internal Error", { status: 500 });
  }
});
