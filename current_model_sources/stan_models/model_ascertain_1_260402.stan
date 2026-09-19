data {
  int<lower=1> N;                           // 总观测数
  int<lower=1> S;                           // 被试数
  array[N] int<lower=1, upper=S> subject;   // 被试ID
  vector[N] x;                              // 自变量（必须已标准化：均值0，标准差1）
  vector[N] y;                             
}

parameters {
  // 群体水平参数
  real mu_int;
  real mu_slo;
  
  // 群体水平标准差 - 分两侧
  real<lower=0> sigma_int;
  real<lower=0> sigma_slo;
  
  // ---- 非中心参数化的核心 ----
  // 个体参数扰动项 - 分两侧
  vector[S] z_int;
  vector[S] z_slo;
  
  real<lower=0> sigma_obs;
  // 允许 nu 逼近 1，以兼容极端厚尾数据，防止采样器撞墙
  real<lower=2> nu;
  
  // 【新增】：产生精确 0 值的概率
  // real<lower=0, upper=1> theta;
}


transformed parameters {
  // 非中心参数化转换：将标准正态变量转换为实际个体参数
  vector[S] inter = mu_int + sigma_int * z_int;
  vector[S] slope = mu_slo + sigma_slo * z_slo;
}

model {
  /* ---------- 群体水平先验 ---------- */
  // 截距先验 - 分两侧
  mu_int ~ normal(0, 50);        // 根据y尺度调整
  
  // 斜率先验 - 分两侧
  mu_slo ~ normal(0, 15);         // x已标准化

  /* ---------- 变异参数先验 ---------- */
  // 群体层标准差 - 分两侧
  sigma_int ~ normal(0, 15);
  sigma_slo ~ normal(0, 15);
  sigma_obs ~ normal(0, 15);
  
  // 自由度先验保持不变，因为它与 y 的量级无关
  nu ~ gamma(2, 0.1);
  
  // theta 的先验：beta(1, 1) 代表 0~1 之间的均匀分布
  // theta ~ beta(1, 1);
  
  /* ---------- 个体水平先验 ---------- */
  // 非中心参数化先验 - 分两侧
  z_int ~ std_normal();
  z_slo ~ std_normal();

  {  
    vector[N] mu = inter[subject] + slope[subject] .* x;
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
    vector[N] mu = inter[subject] + slope[subject] .* x;
    real mu_gen;
    for (n in 1:N) {
      
        log_lik[n] = student_t_lpdf(y[n] | nu, mu[n], sigma_obs);
        y_rep[n] = student_t_rng(nu, mu[n], sigma_obs); 
    }
  }
}
