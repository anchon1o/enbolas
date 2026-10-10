# En bólas!

Xogo web de carreiras de bólas (canicas): reto do día, modo aposta, modo conducir,
bólas deseñables, editor de pistas co dedo e catro idiomas (galego, català, euskara, castellano).

## Ficheiros
- `index.html` — o xogo enteiro.
- `ranking.html` — só a clasificación do reto do día, lixeira, para incrustar nun iframe (p. ex. en cagando).
- `supabase.sql` — táboas e función no proxecto Supabase `xogos` (prefixo `eb_`).

## ranking.html · parámetros
- `lang` = gl (por defecto), ca, eu, es
- `n` = número de postos (por defecto 10, máximo 100)
- `p` = vista inicial: hoxe (por defecto), semana, mes, sempre
- `v` = variante inicial: curta, normal (por defecto), longa

Exemplo: `ranking.html?lang=gl&n=5&p=hoxe&v=normal`

"Hoxe" calcúlase segundo a hora de España (Europe/Madrid).
