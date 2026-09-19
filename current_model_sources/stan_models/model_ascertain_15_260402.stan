data {
  int<lower=1> N;                           // 总观测数
  int<lower=1> S;                           // 被试数
  array[N] int<lower=1, upper=S> subject;   // 被试ID
  vector[N] outcome;                              // 自变量（必须已标准化：均值0，标准差1）
  vector[N] pe;
  vector[N] y;                              // 因变量（范围0-100）
}

parameters {
  // 群体水平参数 - 分两侧
  real mu_slo_o;                    // x<0侧的斜率群体均值
  real mu_slo_p_pos;                    // x>=0侧的斜率群体均值
  real mu_slo_p_neg;                    // x>=0侧的斜率群体均值
  
  // 群体水平标准差 - 分两侧
  real<lower=0> sigma_slo_o;
  real<lower=0> sigma_slo_p_pos;
  real<lower=0> sigma_slo_p_neg;
  
  // ---- 非中心参数化的核心 ----
  // 个体参数扰动项 - 分两侧
  vector[S] z_slo_o;                // x<0侧的个体斜率扰动
  vector[S] z_slo_p_pos;                // x>=0侧的个体斜率扰动
  vector[S] z_slo_p_neg;                // x>=0侧的个体斜率扰动
  
  real<lower=0> sigma_obs;           
  real<lower=2> nu;
}


transformed parameters {
  // 非中心参数化转换：将标准正态变量转换为实际个体参数
  vector[S] slo_o = mu_slo_o + sigma_slo_o * z_slo_o;
  vector[S] slo_p_pos = mu_slo_p_pos + sigma_slo_p_pos * z_slo_p_pos;
  vector[S] slo_p_neg = mu_slo_p_neg + sigma_slo_p_neg * z_slo_p_neg;
}

model {
  /* ---------- 群体水平先验 ---------- */
  // 斜率先验 - 分两侧
  mu_slo_o ~ normal(0, 15);         // x已标准化
  mu_slo_p_pos ~ normal(0, 15);
  mu_slo_p_neg ~ normal(0, 15);
  
  /* ---------- 变异参数先验 ---------- */
  // 群体层标准差 - 分两侧
  sigma_slo_o  ~ normal(0, 15);
  sigma_slo_p_pos  ~ normal(0, 15);
  sigma_slo_p_neg  ~ normal(0, 15);
  
  sigma_obs ~ normal(0, 15);
  
  /* ---------- 个体水平先验 ---------- */
  // 非中心参数化先验 - 分两侧
  z_slo_o ~ std_normal();
  z_slo_p_pos ~ std_normal();
  z_slo_p_neg ~ std_normal();
  
  // 自由度先验保持不变，因为它与 y 的量级无关
  nu ~ gamma(2, 0.1);
  
  {
    vector[N] mu;
    // subject loop and trial loop
    for (n in 1:N) {
      
      int s = subject[n];
      
      if (pe[n] < 0) {
        mu[n] = slo_o[s] * outcome[n] + slo_p_neg[s] * pe[n];
      } else {
        mu[n] = slo_o[s] * outcome[n] + slo_p_pos[s] * pe[n];
      }
    }
    // 所有人，不管是不是 0，全部公平地服从这个厚尾分布
    target += student_t_lpdf(y | nu, mu, sigma_obs);
  }
}

generated quantities {
  // ---------- 1. 后验预测值 ----------
  vector[N] y_rep;
  // ---------- 2. 逐点对数似然（loo包必需） ---------- 
  vector[N] log_lik;
  
  real mu;
  
  for (n in 1:N) {
    int s = subject[n];
    mu = (pe[n] < 0) ? (slo_o[s] * outcome[n] + slo_p_neg[s] * pe[n]) : 
                       (slo_o[s] * outcome[n] + slo_p_pos[s] * pe[n]);
                       
    y_rep[n] = student_t_rng(nu, mu, sigma_obs);
    log_lik[n] = student_t_lpdf(y[n] | nu, mu, sigma_obs);
  }
}