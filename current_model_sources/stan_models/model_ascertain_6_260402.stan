data {
  int<lower=1> N;                           // 总观测数
  int<lower=1> S;                           // 被试数
  array[N] int<lower=1, upper=S> subject;   // 被试ID
  vector[N] x;                              // 自变量（必须已标准化：均值0，标准差1）
  vector[N] y;                              // 因变量（范围0-100）
}

parameters {
  // 群体水平参数 - 分两侧
  real mu_int_pos;                   // x>=0侧的截距群体均值
  real mu_slo_neg;                    // x<0侧的斜率群体均值
  real mu_slo_pos;                    // x>=0侧的斜率群体均值
  
  // 群体水平标准差 - 分两侧
  real<lower=0> sigma_int_pos;
  real<lower=0> sigma_slo_neg;
  real<lower=0> sigma_slo_pos;
  
  // ---- 非中心参数化的核心 ----
  // 个体参数扰动项 - 分两侧
  vector[S] z_int_pos;               // x>=0侧的个体截距扰动
  vector[S] z_slo_neg;                // x<0侧的个体斜率扰动
  vector[S] z_slo_pos;                // x>=0侧的个体斜率扰动
  
  real<lower=0> sigma_obs;           
  real<lower=2> nu;
}


transformed parameters {
  // 非中心参数化转换：将标准正态变量转换为实际个体参数
  vector[S] int_pos = mu_int_pos + sigma_int_pos * z_int_pos;
  vector[S] slo_neg = mu_slo_neg + sigma_slo_neg * z_slo_neg;
  vector[S] slo_pos = mu_slo_pos + sigma_slo_pos * z_slo_pos;
}

model {
  /* ---------- 群体水平先验 ---------- */
  // 截距先验 - 分两侧
  mu_int_pos ~ normal(0, 50);
  
  // 斜率先验 - 分两侧
  mu_slo_neg ~ normal(0, 15);          // x已标准化
  mu_slo_pos ~ normal(0, 15); 
  
  /* ---------- 变异参数先验 ---------- */
  // 群体层标准差 - 分两侧
  sigma_int_pos ~ normal(0, 15);
  sigma_slo_neg ~ normal(0, 15);
  sigma_slo_pos ~ normal(0, 15);
  
  sigma_obs ~ normal(0, 15);
  
  /* ---------- 个体水平先验 ---------- */
  // 非中心参数化先验 - 分两侧
  z_int_pos ~ std_normal();
  z_slo_neg ~ std_normal();
  z_slo_pos ~ std_normal();
  
  // 自由度先验保持不变，因为它与 y 的量级无关
  nu ~ gamma(2, 0.1);
  
  {
    // subject loop and trial loop
    vector[N] mu;
    for (n in 1:N) {
      
      int s = subject[n];
      
      if (x[n] < 0) {
        mu[n] = slo_neg[s] * x[n];
      } else {
        mu[n] = int_pos[s] + slo_pos[s] * x[n];
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
  
  {
    real mu_gen;
    for (n in 1:N) {
      int s = subject[n];
        
      // 根据 x 的正负，套用不同的参数
      mu_gen = (x[n] < 0) ? (slo_neg[s] * x[n]) : 
                            (int_pos[s] + slo_pos[s] * x[n]);
                             
      y_rep[n] = student_t_rng(nu, mu_gen, sigma_obs);
      log_lik[n] = student_t_lpdf(y[n] | nu, mu_gen, sigma_obs);
    }
  }
}