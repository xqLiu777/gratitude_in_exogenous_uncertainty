data {
  int<lower=1> N;                           // 总观测数
  int<lower=1> S;                           // 被试数
  array[N] int<lower=1, upper=S> subject;   // 被试ID
  vector[N] x;                              // 自变量（必须已标准化：均值0，标准差1）
  vector[N] y;                              // 因变量（范围-50-50）
}

parameters {
  // 截距参数：全局截距 + 正负侧附加值
  real mu_int_general;
  real mu_int_neg_add;
  real mu_int_pos_add;
  
  // 斜率群体均值保持原结构
  real mu_slo_neg;
  real mu_slo_pos;
  
  // 群体水平标准差 - 分两侧
  real<lower=0> sigma_int_neg;
  real<lower=0> sigma_int_pos;
  real<lower=0> sigma_slo_neg;
  real<lower=0> sigma_slo_pos;
  
  // ---- 非中心参数化的核心 ----
  // 个体参数扰动项 - 分两侧
  vector[S] z_int_neg;               // x<0侧的个体截距扰动
  vector[S] z_int_pos;               // x>=0侧的个体截距扰动
  vector[S] z_slo_neg;                // x<0侧的个体斜率扰动
  vector[S] z_slo_pos;                // x>=0侧的个体斜率扰动
  
  real<lower=0> sigma_obs;        
  real<lower=1> nu;
}

transformed parameters {
  // 组合截距参数，还原为你需要的群体均值
  real mu_int_neg = mu_int_general + mu_int_neg_add;
  real mu_int_pos = mu_int_general + mu_int_pos_add;

  // 非中心参数化转换：将标准正态变量转换为实际个体参数
  vector[S] int_neg = mu_int_neg + sigma_int_neg * z_int_neg;
  vector[S] int_pos = mu_int_pos + sigma_int_pos * z_int_pos;
  vector<lower=0>[S] slo_neg = exp(mu_slo_neg + sigma_slo_neg * z_slo_neg);
  vector<lower=0>[S] slo_pos = exp(mu_slo_pos + sigma_slo_pos * z_slo_pos);
}

model {
  /* ---------- 群体水平先验 ---------- */
  // 截距的强信息先验 (引入全局截距和正负附加值，精准锁定相对大小)
  mu_int_general ~ normal(0.95, 0.5);
  mu_int_neg_add ~ normal(-0.41, 0.2);
  mu_int_pos_add ~ normal(0.41, 0.2);
  
  // 斜率的强信息先验 (已转换至对数尺度)
  mu_slo_neg ~ normal(1.67, 0.2);          
  mu_slo_pos ~ normal(1.87, 0.2);
  
  /* ---------- 变异参数先验 ---------- */
  // 群体层标准差赋予预期的先验 (斜率SD同为对数尺度)
  sigma_int_neg ~ normal(1.89, 0.5);
  sigma_int_pos ~ normal(3.04, 0.5);
  sigma_slo_neg ~ normal(0.98, 0.2);
  sigma_slo_pos ~ normal(0.85, 0.2);
  
  sigma_obs ~ normal(0, 15);
  
  /* ---------- 个体水平先验 ---------- */
  // 非中心参数化先验 - 分两侧
  z_int_neg ~ std_normal();
  z_int_pos ~ std_normal();
  z_slo_neg ~ std_normal();
  z_slo_pos ~ std_normal();
  
  // 自由度先验保持不变
  nu ~ gamma(2, 0.1);
  
  {
    // 在局部环境 {} 里计算 mu，算完即焚，不占内存
    vector[N] mu;
    for (n in 1:N) {
      int s = subject[n];
      if (x[n] < 0) {
        mu[n] = int_neg[s] + slo_neg[s] * x[n];
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
      if (x[n] < 0) {
        mu_gen = int_neg[s] + slo_neg[s] * x[n];
      } else {
        mu_gen = int_pos[s] + slo_pos[s] * x[n];
      }
      
      // 生成似然值和预测值
      log_lik[n] = student_t_lpdf(y[n] | nu, mu_gen, sigma_obs);
      y_rep[n] = student_t_rng(nu, mu_gen, sigma_obs);
    }
  }
}